#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
swift build -c release "$@"
binary_dir="$(swift build -c release --show-bin-path "$@")"
app_dir="$PWD/dist/NetSpeed.app"
mkdir -p "$app_dir/Contents/MacOS"
cp "$binary_dir/NetSpeed" "$app_dir/Contents/MacOS/NetSpeed"
cp Info.plist "$app_dir/Contents/Info.plist"
codesign --force --sign - "$app_dir"
echo "Built $app_dir"
