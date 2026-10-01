# 🖥️ LG Monitor Control for macOS

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple&style=flat-square)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Architecture-Apple%20Silicon-orange?style=flat-square)](https://support.apple.com/en-us/HT211814)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&style=flat-square)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

A fast, lightweight, and native macOS Menu Bar App and CLI tool designed specifically for Apple Silicon Macs to control **Brightness**, **Contrast**, and **Volume** (plus Mute) on external LG monitors (such as LG UltraFine, UltraGear, and 4K/5K/6K displays).

Crafted following **Apple Human Interface Guidelines (HIG)** with dynamic **Light and Dark Mode** support, San Francisco typography, and zero background bloat.

---

## 💡 Why LG OnScreen Control (OSC) Fails on Apple Silicon

LG's official **OnScreen Control (OSC)** software is notorious for issues on Apple Silicon Macs:
1. **Broken DDC/CI over Thunderbolt / USB4**: LG OSC relies on legacy kernel-level calls that fail to communicate across modern Thunderbolt 4 / USB4 display topologies.
2. **macOS Volume Lockout**: macOS disables native volume keys for external DisplayPort / Thunderbolt monitors by default, and LG OSC provides no volume or mute controls.
3. **Heavy Background Daemons**: LG OSC runs background helper processes (`OSCMultiMonitor`, `libDeviceManager.dylib`, etc.) that frequently crash or drain CPU resources on newer macOS versions.

**LG Monitor Control** solves this by communicating directly with the display via **VESA DDC/CI (VCP)** using Apple Silicon's native `CoreDisplay` and `IOAVService` interfaces. It runs in-process with **zero background daemons**, **zero kernel extensions**, and **instant response time**.

---

## ✨ Features

- 🎛️ **Full Hardware Control**:
  - ☀️ **Brightness (Luminance)**: 0% – 100%
  - 🌓 **Contrast**: 0% – 100%
  - 🔊 **Volume**: 0% – 100% with dedicated **Mute / Unmute** toggle
- 🎨 **Apple HIG Design & Dynamic Themes**:
  - Automatically switches between **Light Mode** (frosted white vibrancy glass with crisp black accents) and **Dark Mode** (frosted obsidian glass with crisp off-white accents).
  - Authentic Apple San Francisco typography with `.monospacedDigit()` for jitter-free alignment.
- 🚀 **Two Modes of Use**:
  1. **Menu Bar Popover**: Lives in your macOS menu bar as a sleek display icon. Click once to adjust sliders or tap presets.
  2. **Detachable Floating Window**: Click **Detach** to pop the controls into a dedicated floating window on your desktop.
- ⚡ **Precision Steppers & Quick Presets**:
  - `[-]` and `[+]` 5% adjustment steppers for fine-tuning.
  - Percentage pills (`25%`, `50%`, `75%`, `100%`) with high-contrast active inversion.
  - **Quick Profiles**:
    - 🌙 **Night**: 20% Brightness / 60% Contrast
    - 📖 **Read**: 40% Brightness / 65% Contrast
    - ☀️ **Day**: 75% Brightness / 70% Contrast
    - ⚡ **Max**: 100% Brightness / 80% Contrast
- 🧵 **Hardware Throttling / Debouncing**: Hardware writes over DDC/CI I2C are smoothly throttled to ensure responsive, lag-free slider movement without bus congestion.
- 💻 **CLI Companion Tool (`lg-control`)**: Control your monitor directly from Terminal, Raycast, Alfred, or Apple Shortcuts.

---

## 📦 Installation & Setup

### Prerequisites
- macOS 13.0 (Ventura) or newer (Sonoma, Sequoia, and macOS 27+ supported).
- Apple Silicon Mac (M1, M2, M3, M4 series).
- Monitor connected via Thunderbolt, USB4, or USB-C (DisplayPort Alt Mode).
- **DDC/CI** enabled in your monitor's built-in OSD menu (`Settings -> General / Picture -> DDC/CI: On`).

### 1. Clone & Build
```bash
git clone https://github.com/ajeygore/LG-Controls.git
cd LG-Controls

# Compile the app and CLI, and install into /Applications and /opt/homebrew/bin
make install
```

### 2. Launch App
```bash
open "/Applications/LG Control.app"
```
The display icon will appear in your top menu bar.

---

## ⌨️ Command-Line Interface (`lg-control`)

The installation script symlinks `lg-control` to `/opt/homebrew/bin/lg-control` (or `/usr/local/bin/lg-control`), making it accessible from anywhere:

```bash
# Check current monitor settings
lg-control status

# Set or get Brightness (0-100)
lg-control brightness 50
lg-control brightness          # Prints current value: 50

# Set or get Contrast (0-100)
lg-control contrast 70
lg-control contrast            # Prints current value: 70

# Set or get Volume (0-100)
lg-control volume 30
lg-control volume              # Prints current value: 30

# Mute or Unmute audio
lg-control mute
lg-control unmute

# Quick Profiles
lg-control preset night        # 20% Brightness, 60% Contrast
lg-control preset read         # 40% Brightness, 65% Contrast
lg-control preset day          # 75% Brightness, 70% Contrast
lg-control preset cinema       # 100% Brightness, 80% Contrast
```

---

## 🛠️ Architecture & Project Structure

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
│   ├── ContentView.swift      # SwiftUI interface with Apple HIG styling
│   ├── MonitorViewModel.swift # Reactive state management with debounced DDC writes
│   ├── main.swift             # App entry point
│   └── CLI.swift              # Standalone CLI binary (`lg-control`)
├── Resources/
│   ├── AppIcon.icns           # High-resolution macOS application icon
│   └── Info.plist             # Menu bar agent configuration
├── Scripts/
│   └── build.sh               # Standalone compilation script
├── Makefile                   # Build, install, run, and clean targets
├── LICENSE                    # MIT License
└── README.md
```

### Technical Details
- **Display Discovery**: Uses `CGGetOnlineDisplayList` and `CoreDisplay_DisplayCreateInfoDictionary` to resolve connected IOKit framebuffer shims and detect `DCPAVServiceProxy` services for external displays.
- **DDC/CI Packets**:
  - `LUMINANCE` (VCP `0x10`)
  - `CONTRAST` (VCP `0x12`)
  - `VOLUME` (VCP `0x62`)
  - `MUTE` (VCP `0x8D`)
- **Transport**: Communicates directly through Apple's `IOAVServiceWriteI2C` and `IOAVServiceReadI2C` APIs without spawning sub-processes.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
