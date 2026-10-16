import Foundation
import Darwin

public struct Counters: Sendable {
    public let received: UInt64
    public let sent: UInt64

    public init(received: UInt64, sent: UInt64) {
        self.received = received
        self.sent = sent
    }
}

public struct Speed: Sendable {
    public let download: Double
    public let upload: Double
}

public struct RateCalculator {
    private var previous: [String: Counters] = [:]
    private var previousTime: TimeInterval?

    public init() {}

    public mutating func sample(_ counters: [String: Counters], at time: TimeInterval) -> Speed {
        defer {
            previous = counters
            previousTime = time
        }
        guard let previousTime, time > previousTime else {
            return Speed(download: 0, upload: 0)
        }
        var received = 0.0
        var sent = 0.0
        for (name, current) in counters {
            guard let old = previous[name] else { continue }
            if current.received >= old.received {
                received += Double(current.received - old.received)
            }
            if current.sent >= old.sent {
                sent += Double(current.sent - old.sent)
            }
        }
        let elapsed = time - previousTime
        // A long gap means the Mac slept; begin again rather than showing a stale average.
        guard elapsed < 5 else { return Speed(download: 0, upload: 0) }
        return Speed(download: received / elapsed, upload: sent / elapsed)
    }
}

public enum NetworkInterfaces {
    public static func counters() throws -> [String: Counters] {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        defer { freeifaddrs(addresses) }
        var result: [String: Counters] = [:]
        var cursor = addresses
        while let pointer = cursor {
            let interface = pointer.pointee
            cursor = interface.ifa_next
            guard let address = interface.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_LINK),
                  interface.ifa_flags & UInt32(IFF_UP) != 0,
                  interface.ifa_flags & UInt32(IFF_RUNNING) != 0,
                  let data = interface.ifa_data else { continue }
            let name = String(cString: interface.ifa_name)
            // Physical Wi-Fi/Ethernet interfaces use en*. Exclude loopback,
            // VPN tunnels and virtual bridges so traffic is counted once.
            guard name.hasPrefix("en") else { continue }
            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            result[name] = Counters(received: UInt64(stats.ifi_ibytes), sent: UInt64(stats.ifi_obytes))
        }
        return result
    }
}

public func formatSpeed(_ bytesPerSecond: Double) -> String {
    let value = max(0, bytesPerSecond.isFinite ? bytesPerSecond : 0)
    if value >= 1_000_000_000 { return String(format: "%.1f GB/s", value / 1_000_000_000) }
    if value >= 1_000_000 { return String(format: "%.1f MB/s", value / 1_000_000) }
    if value >= 1_000 { return String(format: "%.0f KB/s", value / 1_000) }
    return String(format: "%.0f B/s", value)
}
