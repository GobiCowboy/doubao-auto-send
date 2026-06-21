# doubao-auto-send

<p align="center">
  <a href="README.zh.md">中文</a> | <b>English</b>
</p>

> Double-tap Left Control to auto-send Enter. A lightweight macOS utility.

## Why?

When using voice input (e.g. Doubao/Sogou IME), you finish speaking and want to send the message — but your hand has moved away from the keyboard. Now you need to reach for Enter.

This tool lets you **double-tap Left Control** to send Enter instantly. One-hand operation, no hand movement needed.

## How It Works

```
Fn trigger voice input → speak → release → double-tap Left Control → message sent
```

## Installation

### Option 1: Download (Recommended)

1. Go to [Releases](https://github.com/GobiCowboy/doubao-auto-send/releases) and download `AutoSend.app`
2. Drag it to `/Applications`, or use the release package that installs it there for you
3. Open the settings page after first launch to choose language, launch-at-login, and permissions

### Option 2: Build from Source

Requires macOS 13.0+ and Xcode Command Line Tools:

```bash
cd Swift
make install
```

This produces a local signed bundle for your own machine. For distribution, use the release script below.

### Option 3: Python Version

```bash
pip3 install pyobjc-framework-Quartz pyobjc-framework-ApplicationServices
python3 auto_send.py
```

## Permissions

Before first run, grant access in **System Settings → Privacy & Security**:

1. **Accessibility** — check AutoSend
2. **Input Monitoring** — check AutoSend
3. Restart the app if needed

## Features

- **Double-tap detection**: Two quick Left Control taps (within 300ms) trigger Enter
- **Menu bar resident**: Status item keeps only the minimal actions
- **Separate settings page**: Language, launch at login, and permissions live in one dedicated window
- **Listen-only mode**: Does not intercept or modify any keyboard events
- **Visual feedback**: Menu bar icon flashes green on trigger

## Compatibility

| Item | Details |
|------|---------|
| macOS | 13.0+ (Swift) / 12.0+ (Python) |
| Input method | Any — Doubao, Sogou, built-in, etc. |
| Apps | Any — WeChat, browser, Slack, Terminal, etc. |
| Shortcut conflicts | Left Control is rarely used alone on macOS, no conflicts |

## Technical Details

Uses macOS `CGEventTap` to listen for `flagsChanged` events, detecting the Left Control key (keyCode 59) down-up-down sequence. If two presses occur within 300ms, it simulates an Enter keypress (keyCode 36) via `CGEventPost`.

## Release

For distribution outside your own Mac, use Developer ID signing + notarization + stapling. The release script signs the app, submits it to Apple, staples the ticket, verifies the result, and installs the final bundle to `/Applications`.

```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE=Apple-Notary \
./scripts/release_arm64.sh
```

## Project Structure

```
doubao-auto-send/
├── README.md
├── auto_send.py          # Python version
├── requirements.txt
├── setup.sh
└── Swift/
    ├── Package.swift
    ├── Info.plist
    ├── Makefile
    ├── Resources/        # App icon
    └── Sources/AutoSend/ # Native Swift version
```

## License

MIT
