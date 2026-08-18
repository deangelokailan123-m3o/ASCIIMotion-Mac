# ASCIIMotion-Mac

A simple frame-by-frame ASCII animation creator for macOS, built with **Swift and AppKit**.

ASCIIMotion lets you create little animations using nothing but text characters. Make stick figures, spaceships, faces, creatures, words, or whatever else you can build with ASCII.

## Features

* Create frame-by-frame ASCII animations
* Editable ASCII canvas
* Add, duplicate, and delete frames
* Previous and next frame controls
* Play and stop animation
* Adjustable FPS
* Save projects as `.asciimotion` files
* Open saved ASCIIMotion projects
* Human-readable project files
* Native macOS interface
* Drag-to-Applications DMG installer

## `.asciimotion` Files

ASCIIMotion project files are intentionally human-readable.

They store the animation frames and FPS as JSON, which means you can even open a `.asciimotion` file in a text editor and modify it manually.

Example:

```json
{
  "fps": 4,
  "frames": [
    "(^_^)",
    "(O_O)",
    "(-_-)"
  ]
}
```

Save the file and reopen it in ASCIIMotion to see your changes.

## Requirements

ASCIIMotion v0.1 is built for:

* macOS 12 Monterey or later
* Intel or compatible Mac hardware supported by the build

## Installation

1. Download `ASCIIMotion-v0.1.dmg` from the Releases page.
2. Open the DMG.
3. Drag **ASCIIMotion** into **Applications**.
4. Open ASCIIMotion from your Applications folder.

> ASCIIMotion v0.1 is currently distributed without Apple notarization or a Developer ID signature. macOS Gatekeeper may display a security warning.

## Building From Source

ASCIIMotion does **not** require the full Xcode application to compile.

You need the Xcode Command Line Tools and Swift compiler.

Compile the application directly with:

```zsh
swiftc main.swift -framework AppKit -o ASCIIMotion
```

The repository also includes the release build script used to create the macOS `.app` bundle and DMG.

Make it executable:

```zsh
chmod +x build_everything.command
```

Then run:

```zsh
./build_everything.command
```

The build system uses:

* `swiftc` to compile ASCIIMotion
* AppKit for the native macOS interface
* Swift/AppKit to generate the DMG background PNG
* `hdiutil` to create the disk image
* AppleScript/Finder to configure the drag-to-Applications installer

## Version

Current release:

**ASCIIMotion v0.1**

This is the first public release of ASCIIMotion.

## License

ASCIIMotion is released under the **MIT License**.

Copyright (c) 2026 deangelokailan123-m3o

See the `LICENSE` file for the complete license text.

---

Made with Swift, AppKit, ASCII characters, and an unreasonable amount of DMG debugging. :)

