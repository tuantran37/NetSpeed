import AppKit
import NetworkCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var calculator = RateCalculator()
    private let downloadItem = NSMenuItem(title: "Download: —", action: nil, keyEquivalent: "")
    private let uploadItem = NSMenuItem(title: "Upload: —", action: nil, keyEquivalent: "")
    private let interfacesItem = NSMenuItem(title: "Connecting…", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
            button.cell?.wraps = false
            button.setAccessibilityLabel("Network speed")
        }
        let menu = NSMenu()
        let heading = NSMenuItem(title: "NetSpeed", action: nil, keyEquivalent: "")
        menu.addItem(heading)
        menu.addItem(.separator())
        menu.addItem(downloadItem)
        menu.addItem(uploadItem)
        menu.addItem(interfacesItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Speeds in bytes per second · updates every second", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit NetSpeed", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        update()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func update() {
        do {
            let counters = try NetworkInterfaces.counters()
            let speed = calculator.sample(counters, at: ProcessInfo.processInfo.systemUptime)
            let download = formatSpeed(speed.download)
            let upload = formatSpeed(speed.upload)
            statusItem.button?.title = "↓ \(download)  ↑ \(upload)"
            statusItem.button?.toolTip = "Download: \(download) · Upload: \(upload)"
            statusItem.button?.setAccessibilityValue("Download \(download), upload \(upload)")
            downloadItem.title = "↓ Download: \(download)"
            uploadItem.title = "↑ Upload: \(upload)"
            interfacesItem.title = counters.isEmpty
                ? "No active Wi-Fi or Ethernet interface"
                : "Interfaces: \(counters.keys.sorted().joined(separator: ", "))"
        } catch {
            statusItem.button?.title = "↓ —  ↑ —"
            statusItem.button?.toolTip = error.localizedDescription
            interfacesItem.title = "Unable to read network counters"
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
