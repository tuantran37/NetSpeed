import XCTest
@testable import NetworkCore

final class NetworkCoreTests: XCTestCase {
    func testRatesUseElapsedTimeAndSumInterfaces() {
        var meter = RateCalculator()
        let first = meter.sample(["en0": Counters(received: 100, sent: 50)], at: 10)
        XCTAssertEqual(first.download, 0)
        let second = meter.sample(["en0": Counters(received: 1100, sent: 550)], at: 12)
        XCTAssertEqual(second.download, 500)
        XCTAssertEqual(second.upload, 250)
    }

    func testNewInterfacesAndCounterResetsDoNotCauseSpikes() {
        var meter = RateCalculator()
        _ = meter.sample(["en0": Counters(received: 1000, sent: 1000)], at: 1)
        let speed = meter.sample([
            "en0": Counters(received: 10, sent: 10),
            "en1": Counters(received: 999_999, sent: 999_999)
        ], at: 2)
        XCTAssertEqual(speed.download, 0)
        XCTAssertEqual(speed.upload, 0)
        let next = meter.sample([
            "en0": Counters(received: 20, sent: 30),
            "en1": Counters(received: 1_000_009, sent: 1_000_019)
        ], at: 3)
        XCTAssertEqual(next.download, 20)
        XCTAssertEqual(next.upload, 40)
    }

    func testSleepAndDisconnectResetBaseline() {
        var meter = RateCalculator()
        _ = meter.sample(["en0": Counters(received: 10, sent: 10)], at: 1)
        XCTAssertEqual(meter.sample(["en0": Counters(received: 500, sent: 500)], at: 100).download, 0)
        XCTAssertEqual(meter.sample([:], at: 101).download, 0)
        XCTAssertEqual(meter.sample(["en0": Counters(received: 900, sent: 900)], at: 102).download, 0)
    }

    func testFormatting() {
        XCTAssertEqual(formatSpeed(0), "0 B/s")
        XCTAssertEqual(formatSpeed(1500), "2 KB/s")
        XCTAssertEqual(formatSpeed(2_500_000), "2.5 MB/s")
        XCTAssertEqual(formatSpeed(1_200_000_000), "1.2 GB/s")
        XCTAssertEqual(formatSpeed(.nan), "0 B/s")
    }

    func testSystemCountersCanBeRead() throws {
        let counters = try NetworkInterfaces.counters()
        XCTAssertTrue(counters.keys.allSatisfy { $0.hasPrefix("en") })
    }
}
