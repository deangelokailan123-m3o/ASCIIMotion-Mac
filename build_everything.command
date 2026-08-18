#!/bin/zsh

# ============================================================
# ASCIIMotion v0.2
# Full macOS APP + DMG Builder
# ZSH
# ============================================================

APP_NAME="ASCIIMotion"
VERSION="0.1"
BUNDLE_ID="com.kai.asciimotion"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="$PROJECT_DIR/main.swift"

BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

DMG_STAGE="$BUILD_DIR/dmg-stage"

BACKGROUND_SWIFT="$BUILD_DIR/DMGBackground.swift"
BACKGROUND_EXEC="$BUILD_DIR/DMGBackground"
BACKGROUND_PNG="$BUILD_DIR/background.png"

TEMP_DMG="$BUILD_DIR/ASCIIMotion-temp.dmg"
FINAL_DMG="$PROJECT_DIR/ASCIIMotion-v$VERSION.dmg"

VOLUME_NAME="ASCIIMotion $VERSION"
MOUNT_POINT="/Volumes/$VOLUME_NAME"

# ============================================================
# FUNCTIONS
# ============================================================

pause_end() {
    echo ""
    read "reply?Press ENTER to close..."
}

fail() {
    echo ""
    echo "============================================================"
    echo "                    BUILD FAILED"
    echo "============================================================"
    echo ""
    echo "$1"
    echo ""
    pause_end
    exit 1
}

cleanup() {
    if [[ -d "$MOUNT_POINT" ]]; then
        echo "Unmounting leftover DMG..."
        hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1
    fi
}

trap cleanup EXIT

# ============================================================
# START
# ============================================================

clear

echo "============================================================"
echo "             ASCIIMotion BUILD SYSTEM"
echo "============================================================"
echo ""
echo "Version: $VERSION"
echo "Project: $PROJECT_DIR"
echo ""

# ============================================================
# CHECK FILE
# ============================================================

if [[ ! -f "$SOURCE_FILE" ]]; then
    fail "main.swift was not found."
fi

# ============================================================
# STEP 1
# ============================================================

echo "[1/12] Cleaning old build..."

cleanup

rm -rf "$BUILD_DIR"
rm -f "$FINAL_DMG"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$DMG_STAGE"

echo "DONE"
echo ""

# ============================================================
# STEP 2
# ============================================================

echo "[2/12] Compiling ASCIIMotion..."

swiftc \
    "$SOURCE_FILE" \
    -framework AppKit \
    -o "$MACOS_DIR/$APP_NAME"

if [[ $? -ne 0 ]]; then
    fail "ASCIIMotion failed to compile."
fi

chmod +x "$MACOS_DIR/$APP_NAME"

echo "DONE"
echo ""

# ============================================================
# STEP 3
# ============================================================

echo "[3/12] Creating Info.plist..."

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>

    <key>CFBundleName</key>
    <string>$APP_NAME</string>

    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>

    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>

    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleVersion</key>
    <string>$VERSION</string>

    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>

    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>

    <key>NSHighResolutionCapable</key>
    <true/>

    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>

            <key>CFBundleTypeName</key>
            <string>ASCIIMotion Project</string>

            <key>CFBundleTypeExtensions</key>
            <array>
                <string>asciimotion</string>
            </array>

            <key>CFBundleTypeRole</key>
            <string>Editor</string>

            <key>LSHandlerRank</key>
            <string>Owner</string>

        </dict>
    </array>

</dict>
</plist>
EOF

echo "DONE"
echo ""

# ============================================================
# STEP 4
# ============================================================

echo "[4/12] Creating Swift background generator..."

cat > "$BACKGROUND_SWIFT" <<'SWIFT'
import AppKit
import Foundation

let width: CGFloat = 640
let height: CGFloat = 420

let image = NSImage(
    size: NSSize(
        width: width,
        height: height
    )
)

image.lockFocus()

// Background gradient

let gradient = NSGradient(
    starting: NSColor(
        calibratedRed: 0.07,
        green: 0.08,
        blue: 0.13,
        alpha: 1.0
    ),
    ending: NSColor(
        calibratedRed: 0.18,
        green: 0.20,
        blue: 0.30,
        alpha: 1.0
    )
)!

gradient.draw(
    in: NSRect(
        x: 0,
        y: 0,
        width: width,
        height: height
    ),
    angle: -90
)

// Title

let titleStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(
        ofSize: 34,
        weight: .bold
    ),
    .foregroundColor: NSColor.white
]

"ASCIIMotion".draw(
    at: NSPoint(
        x: 30,
        y: 355
    ),
    withAttributes: titleStyle
)

// Subtitle

let subtitleStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(
        ofSize: 16,
        weight: .regular
    ),
    .foregroundColor: NSColor(
        calibratedWhite: 0.76,
        alpha: 1.0
    )
]

"ASCII animation for macOS".draw(
    at: NSPoint(
        x: 32,
        y: 326
    ),
    withAttributes: subtitleStyle
)

// Arrow

let arrowStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(
        ofSize: 76,
        weight: .bold
    ),
    .foregroundColor: NSColor.white
]

"➜".draw(
    at: NSPoint(
        x: 285,
        y: 180
    ),
    withAttributes: arrowStyle
)

// Instructions

let instructionStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(
        ofSize: 17,
        weight: .semibold
    ),
    .foregroundColor: NSColor.white
]

"Drag ASCIIMotion into Applications".draw(
    at: NSPoint(
        x: 175,
        y: 105
    ),
    withAttributes: instructionStyle
)

// ASCII decoration

let asciiStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(
        ofSize: 15,
        weight: .regular
    ),
    .foregroundColor: NSColor(
        calibratedWhite: 0.55,
        alpha: 1.0
    )
]

let asciiArt = """
Frame 1        Frame 2        Frame 3

   O              \\O             \\O/
  /|\\              |\\             |
  / \\             / \\            / \\
"""

asciiArt.draw(
    at: NSPoint(
        x: 115,
        y: 20
    ),
    withAttributes: asciiStyle
)

image.unlockFocus()

guard CommandLine.arguments.count >= 2 else {
    print("No output file specified.")
    exit(1)
}

let output = CommandLine.arguments[1]

guard let tiff = image.tiffRepresentation else {
    print("Could not create TIFF.")
    exit(1)
}

guard let bitmap = NSBitmapImageRep(data: tiff) else {
    print("Could not create bitmap.")
    exit(1)
}

guard let png = bitmap.representation(
    using: .png,
    properties: [:]
) else {
    print("Could not create PNG.")
    exit(1)
}

do {
    try png.write(
        to: URL(
            fileURLWithPath: output
        )
    )

    print("Background created:")
    print(output)

} catch {
    print(error.localizedDescription)
    exit(1)
}
SWIFT

echo "DONE"
echo ""

# ============================================================
# STEP 5
# ============================================================

echo "[5/12] Compiling background generator..."

swiftc \
    "$BACKGROUND_SWIFT" \
    -framework AppKit \
    -o "$BACKGROUND_EXEC"

if [[ $? -ne 0 ]]; then
    fail "Background generator failed to compile."
fi

echo "DONE"
echo ""

# ============================================================
# STEP 6
# ============================================================

echo "[6/12] Generating background.png..."

"$BACKGROUND_EXEC" "$BACKGROUND_PNG"

if [[ $? -ne 0 ]]; then
    fail "Background generator failed."
fi

if [[ ! -f "$BACKGROUND_PNG" ]]; then
    fail "background.png was not created."
fi

echo "DONE"
echo ""

# ============================================================
# STEP 7
# ============================================================

echo "[7/12] Preparing DMG folder..."

cp -R \
    "$APP_DIR" \
    "$DMG_STAGE/$APP_NAME.app"

ln -s \
    /Applications \
    "$DMG_STAGE/Applications"

# IMPORTANT:
# Put PNG directly at root for Finder first.
cp \
    "$BACKGROUND_PNG" \
    "$DMG_STAGE/background.png"

echo ""
echo "DMG stage contains:"
ls -la "$DMG_STAGE"
echo ""

echo "DONE"
echo ""

# ============================================================
# STEP 8
# ============================================================

echo "[8/12] Creating writable DMG..."

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_STAGE" \
    -fs HFS+ \
    -format UDRW \
    -ov \
    "$TEMP_DMG"

if [[ $? -ne 0 ]]; then
    fail "hdiutil could not create writable DMG."
fi

echo "DONE"
echo ""

# ============================================================
# STEP 9
# ============================================================

echo "[9/12] Mounting writable DMG..."

ATTACH_OUTPUT="$(
    hdiutil attach \
        "$TEMP_DMG" \
        -readwrite \
        -noverify \
        -noautoopen
)"

echo "$ATTACH_OUTPUT"
echo ""

DEVICE="$(
    echo "$ATTACH_OUTPUT" |
    awk '/^\/dev\// {print $1; exit}'
)"

if [[ -z "$DEVICE" ]]; then
    fail "Could not find DMG device."
fi

sleep 2

if [[ ! -d "$MOUNT_POINT" ]]; then
    fail "Mounted volume was not found."
fi

echo "Device:"
echo "$DEVICE"

echo ""
echo "Mounted at:"
echo "$MOUNT_POINT"

echo ""
echo "Files inside DMG:"
ls -la "$MOUNT_POINT"

echo ""

if [[ ! -f "$MOUNT_POINT/background.png" ]]; then
    fail "background.png is NOT inside the mounted DMG."
fi

echo "BACKGROUND FOUND."
echo "DONE"
echo ""

# ============================================================
# STEP 10
# ============================================================

echo "[10/12] Styling Finder window..."

# Use a simple ROOT file instead of .background.
# This avoids Finder's problem resolving hidden folder paths.

osascript <<EOF
tell application "Finder"

    tell disk "$VOLUME_NAME"

        open

        delay 2

        set dmgWindow to container window

        set current view of dmgWindow to icon view

        set toolbar visible of dmgWindow to false
        set statusbar visible of dmgWindow to false

        set bounds of dmgWindow to {200, 150, 840, 570}

        set dmgViewOptions to icon view options of dmgWindow

        set arrangement of dmgViewOptions to not arranged

        set icon size of dmgViewOptions to 96
        set text size of dmgViewOptions to 14

        set background picture of dmgViewOptions to file "background.png"

        set position of item "$APP_NAME.app" to {155, 205}

        set position of item "Applications" to {485, 205}

        update without registering applications

        delay 3

    end tell

end tell
EOF

APPLE_RESULT=$?

if [[ $APPLE_RESULT -ne 0 ]]; then
    fail "Finder could not style the DMG."
fi

echo "Finder styling succeeded."
echo ""

# Hide the PNG AFTER Finder has already selected it.

echo "Hiding background.png..."

chflags hidden "$MOUNT_POINT/background.png"

sync

sleep 2

echo "DONE"
echo ""

# ============================================================
# STEP 11
# ============================================================

echo "[11/12] Closing Finder window and ejecting DMG..."

osascript <<EOF
tell application "Finder"

    try

        tell disk "$VOLUME_NAME"

            close container window

        end tell

    end try

end tell
EOF

sync

sleep 2

hdiutil detach "$DEVICE"

if [[ $? -ne 0 ]]; then
    fail "Could not eject temporary DMG."
fi

trap - EXIT

echo "DONE"
echo ""

# ============================================================
# STEP 12
# ============================================================

echo "[12/12] Creating final compressed DMG..."

hdiutil convert \
    "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$FINAL_DMG"

if [[ $? -ne 0 ]]; then
    fail "Could not create compressed DMG."
fi

rm -f "$TEMP_DMG"

echo ""
echo "============================================================"
echo "                    BUILD COMPLETE"
echo "============================================================"
echo ""
echo "APP:"
echo "$APP_DIR"
echo ""
echo "DMG:"
echo "$FINAL_DMG"
echo ""
echo "Opening the finished DMG..."
echo ""

open "$FINAL_DMG"

echo ""
echo "ASCIIMotion v$VERSION is ready! 🔥"
echo ""

pause_end
