# 🖥️ LG Monitor Control for macOS

A fast, lightweight, and native macOS Menu Bar App and CLI tool designed specifically for Apple Silicon Macs to control **Brightness**, **Contrast**, and **Volume** (plus Mute) on your connected LG monitor.

---

## 💡 Why LG OnScreen Control (OSC) Doesn't Work

LG's official **OnScreen Control (OSC)** software has several well-known limitations on macOS Apple Silicon:
1. **Broken DDC/CI over Thunderbolt/USB4**: LG OSC often fails to establish DDC communication over USB4/Thunderbolt 4 or USB-C DisplayPort Alt Mode on Apple Silicon Macs.
2. **Audio Volume Lockout**: macOS disables native keyboard volume controls and sliders for external DisplayPort/HDMI/Thunderbolt audio outputs by default, and LG OSC does not provide volume or mute controls.
3. **Bloat and Crashes**: LG OSC installs heavy legacy daemons (`OSCMultiMonitor`, `libDeviceManager`, etc.) that frequently crash or fail to communicate with newer macOS versions.

**LG Monitor Control** solves this by speaking directly to the hardware using native **DDC/CI (VESA VCP)** over macOS's private `CoreDisplay` and `IOAVService` interfaces. It runs in-process with **zero background daemons**, **zero kernel extensions**, and **instant response time**.

---

## ✨ Features

- 🎛️ **Full Hardware Control**:
  - ☀️ **Brightness (Luminance)** (0% – 100%)
  - 🌓 **Contrast** (0% – 100%)
  - 🔊 **Volume** (0% – 100%) with **Mute / Unmute** toggle
- 🚀 **Two Modes of Use**:
  1. **Menu Bar Popover**: Lives in your macOS menu bar as a sleek display icon. Click once to adjust sliders or tap presets.
  2. **Detachable Floating Window**: Click **Detach** to pop the controls into a dedicated floating window you can keep on your desktop.
- ⚡ **Quick Presets & Steppers**:
  - `[-]` and `[+]` 5% adjustment steppers for precision tuning.
  - Preset percentage pills (`25%`, `50%`, `75%`, `100%`).
  - **Quick Profiles**:
    - 🌙 **Night**: 20% Brightness / 60% Contrast
    - 📖 **Read**: 40% Brightness / 65% Contrast
    - ☀️ **Day**: 75% Brightness / 70% Contrast
    - 🎬 **Cinema**: 100% Brightness / 80% Contrast
- 🧵 **Smooth Debouncing**: Hardware writes over DDC/CI I2C are throttled to ensure silky smooth slider dragging without bus lag.
- 💻 **CLI Companion Tool (`lg-control`)**: Control your monitor from Terminal, Raycast, Alfred, or Apple Shortcuts.

---

## 📦 Installation & Build

The app and CLI are compiled and installed into `/Applications` and `/opt/homebrew/bin`:

```bash
cd /Users/ajey/Documents/workspace/LG-Controls

# Build and install to /Applications and /opt/homebrew/bin
make install
```

To launch the app:
```bash
open "/Applications/LG Control.app"
```

---

## ⌨️ Command-Line Interface (`lg-control`)

You can query and adjust your monitor from anywhere in the Terminal:

```bash
# Check current hardware values
lg-control status

# Set or get Brightness (0-100)
lg-control brightness 50
lg-control brightness          # Prints current value: 50

# Set or get Contrast (0-100)
lg-control contrast 70
lg-control contrast            # Prints current value: 70

# Set or get Volume (0-100)
lg-control volume 40
lg-control volume              # Prints current value: 40

# Mute / Unmute audio
lg-control mute
lg-control unmute

# Quick Presets
lg-control preset night        # 20% Brightness, 60% Contrast
lg-control preset read         # 40% Brightness, 65% Contrast
lg-control preset day          # 75% Brightness, 70% Contrast
lg-control preset cinema       # 100% Brightness, 80% Contrast
```

---

## 🛠️ Project Structure

```
LG-Controls/
├── DDC/                       # Native DDC/CI communication layer (VESA VCP)
│   ├── DDCBridge.h            # Objective-C to Swift Bridging header
│   ├── DDCManager.h           # High-level DDC interface
│   ├── DDCManager.m           # Thread-safe hardware controller
│   ├── i2c.h / i2c.m          # DDC packet crafting & I2C read/write
│   ├── ioregistry.h / .m      # CoreDisplay & IOKit display discovery
│   └── utils.h
├── Sources/
│   ├── AppDelegate.swift      # Menu bar NSStatusItem & NSPopover management
│   ├── ContentView.swift      # Modern SwiftUI user interface
│   ├── MonitorViewModel.swift # Reactive state management with debounced DDC writes
│   ├── main.swift             # App entry point
│   └── CLI.swift              # Standalone CLI binary (`lg-control`)
├── Resources/
│   ├── AppIcon.icns           # High-resolution macOS application icon
│   └── Info.plist             # Menu bar agent configuration
├── Scripts/
│   └── build.sh               # Standalone compilation script
├── Makefile                   # Build, install, run, and clean targets
└── README.md
```

---

## 🛡️ Requirements & Compatibility

- **Hardware**: Apple Silicon Mac (M1, M2, M3, M4 series).
- **Monitor Connection**: Connected via Thunderbolt, USB4, or USB-C (DisplayPort Alt Mode).
- **Monitor Setting**: Ensure **DDC/CI** is enabled in your LG monitor's built-in On-Screen Display (OSD) settings menu (Menu -> General / Picture -> DDC/CI: On).
