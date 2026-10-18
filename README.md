# NetSpeed

A native macOS menu bar app showing live download (↓) and upload (↑) speeds, updated every second. Click it to see rates, active interfaces, or quit. No Dock icon, dependencies, server, or network permission required.

## Run

Requires macOS 13 or later and Xcode Command Line Tools to build.

```sh
./build-app.sh
open dist/NetSpeed.app
```

Move `dist/NetSpeed.app` to Applications with Finder, then open it once. On its first launch, NetSpeed automatically registers to start when you log in, including after a reboot. If macOS requires approval, enable NetSpeed in System Settings → General → Login Items. You can also disable it there; later launches will respect that choice. Running with `swift run` does not register a login item.

## How it works

Reads local interface byte counters and divides their change by elapsed time. Speeds use decimal bytes per second (1 MB/s = 1,000,000 bytes/s). Counts active physical Wi-Fi/Ethernet `en*` interfaces, excluding loopback, virtual bridges, and VPN tunnels to avoid counting traffic twice. VPN traffic is included through its physical interface, including transport overhead. This measures current traffic, not your connection's maximum capacity. Counter resets, interface changes, and wake from sleep establish a fresh baseline.

```sh
swift test
```

The build script creates an ad hoc signed app for local use on the build machine's architecture. Distribution to other Macs would require Developer ID signing and notarization.
