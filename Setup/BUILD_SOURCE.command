#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$(uname -s)" != Darwin ]]; then echo 'This build requires macOS.'; exit 1; fi
if ! /usr/bin/xcrun --find swiftc >/dev/null 2>&1; then echo 'Install Xcode Command Line Tools first.'; exit 1; fi
build="$repo/build/InjectZ-$(date +%Y%m%d-%H%M%S)-$$"
stage="$build/InjectZ"
app="$stage/InjectZ.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$stage/Development/Reframe" "$stage/Development/IW3"
cp "$repo/App/InjectZ.swift" "$stage/InjectZ.swift"
cp "$repo/SHARP/"*.py "$stage/"
cp "$repo/Reframe/"* "$stage/Development/Reframe/"
cp "$repo/IW3/photo_iw3.py" "$stage/Development/IW3/"
cp "$repo/IW3/create_layered_psd.py" "$stage/Development/"
cp "$repo/IW3/IW3Settings.json" "$repo/IW3/IW3SettingHelp.json" "$stage/"
cp "$repo/Assets/InjectZ.icns" "$repo/Assets/InjectZHeader.png" "$app/Contents/Resources/"
/usr/bin/swiftc -O "$stage/InjectZ.swift" -o "$app/Contents/MacOS/InjectZ" -framework Cocoa -framework UniformTypeIdentifiers -framework ApplicationServices
/usr/bin/swiftc -O "$stage/Development/Reframe/LibraryGuard.swift" -o "$stage/Development/Reframe/LibraryGuard" -framework Cocoa
/bin/cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.injectz.app.dev</string>
<key>CFBundleExecutable</key><string>InjectZ</string>
<key>CFBundleName</key><string>InjectZ</string>
<key>CFBundleDisplayName</key><string>Inject Z</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>InjectZ</string>
<key>CFBundleShortVersionString</key><string>0.2.2</string>
<key>CFBundleVersion</key><string>0.2.2</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppleEventsUsageDescription</key><string>Inject Z controls Photos to create and export stereo working images.</string>
</dict></plist>
PLIST
/usr/bin/plutil -lint "$app/Contents/Info.plist"
echo "Built development staging folder: $stage"
echo 'Not installed or distribution-signed. Dependencies and models must be prepared separately.'
echo 'Read Docs/SETUP.md before using this staged build; do not replace a working app with it.'
