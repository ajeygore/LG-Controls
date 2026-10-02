# 🖥️ LG Monitor Control for macOS

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple&style=flat-square)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Architecture-Apple%20Silicon-orange?style=flat-square)](https://support.apple.com/en-us/HT211814)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&style=flat-square)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

A fast, lightweight, and native macOS Menu Bar App and CLI tool designed specifically for Apple Silicon Macs to control **Brightness**, **Contrast**, and **Volume** (plus Mute) on external monitors.

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
- ⌨️ **Keyboard Brightness & Volume Keys (F1 / F2 / F10 / F11 / F12)**:
  - **Mouse-Aware Targeting**: Adjusts whichever display your mouse cursor is currently resting on!
  - **Seamless Native Coexistence**: If your mouse is on your MacBook's built-in Retina screen, macOS handles brightness natively; move your mouse over your external monitor, and pressing F1/F2 automatically dims or brightens that display via DDC/CI.
  - **Shift + Option Fine Adjustments**: Supports granular 1.25% quarter-step adjustments.
  - **Apple-Style HUD Overlay**: Shows a translucent floating On-Screen Display (OSD) bezel with monitor name, icon, and level bar on the active display.
- 🧵 **Hardware Throttling / Debouncing**: Hardware writes over DDC/CI I2C are smoothly throttled to ensure responsive, lag-free slider movement without bus congestion.
- 💻 **CLI Companion Tool (`lg-control`)**: Control your monitor directly from Terminal, Raycast, Alfred, or Apple Shortcuts.

---

## 🖥️ Supported Monitors & Hardware Compatibility

Because this app utilizes the universal **VESA DDC/CI (Monitor Control Command Set / VCP)** standard, it supports a wide array of monitors across multiple manufacturers:

### 1. LG Monitors (Fully Verified)
- **LG UltraFine Series**:
  - **32U990A** (32" USB4 / Thunderbolt 4 6K)
  - **27MD5KL / 27MD5KA** (27" UltraFine 5K)
  - **24MD4KL** (24" UltraFine 4K)
  - **34WK95U / 34BK95U** (34" 5K2K Nano IPS)
  - **40WP95C / 40WP95CP** (40" 5K2K Curved Thunderbolt 4)
  - **32UN880 / 27UN880** (UltraFine Ergo 4K)
  - **32UQ85R / 32UQ750** (Nano IPS Black 4K)
- **LG UltraGear Gaming Series**:
  - **OLED Series**: 27GR95QE, 32GS95UE, 39GS95QE, 45GR95QE, 48GQ900
  - **IPS 4K / QHD**: 27GP950, 27GN950, 27GP850, 32GP850, 32GQ950
  - **Ultrawide**: 34GP950G, 34GN850, 38GN950, 38GL950G, 38WN95C
- **LG DualUp & Business Displays**:
  - **28MQ780** (DualUp 16:18 aspect ratio)
  - **34WN80C**, **34WP65C**, **34WQ75C**
  - **27UP850**, **27UP650**, **32UP83A**, **27UL850**, **27UK850**

### 2. Dell Monitors (Includes MCDP29XX Bridge Support)
- **Dell UltraSharp Series**:
  - **U2723QE**, **U3223QE** (IPS Black 4K)
  - **U3224KB** (6K Thunderbolt 4)
  - **U4025QW** (40" 5K2K 120Hz Thunderbolt 4)
  - **U3824DW**, **U3425WE**, **U3423WE**, **U2720Q**, **U3219Q**
- **Dell Alienware & Gaming**:
  - **AW3423DWF**, **AW3225QF** (4K QD-OLED), **AW2725DF**, **G3223Q**
- **Dell P & S Series**:
  - **P2723QE**, **P3223QE**, **S2722QC**, **S2721QS**, **S3221QS**

### 3. BenQ Monitors
- **DesignVue & PhotoVue Series**:
  - **PD2705U**, **PD2725U**, **PD3205U**, **PD3220U**, **PD3225U**
  - **SW271C**, **SW321C**
- **MOBIUZ Gaming Series**:
  - **EX2710U**, **EX3210U**, **EX3410R**

### 4. Samsung Monitors
- **ViewFinity Series**:
  - **ViewFinity S9** (27" 5K S90PC)
  - **ViewFinity S8** (S80PB 4K), **ViewFinity S6**
- **Odyssey OLED & Neo Series**:
  - **Odyssey OLED G8** (G80SD, G85SB), **Odyssey OLED G9** (G95SC)
  - **Odyssey Neo G8**, **Odyssey Neo G9**
- **Smart Monitor Series**:
  - **M7**, **M8** (connected via USB-C DisplayPort Alt Mode)

### 5. ASUS Monitors
- **ProArt Series**:
  - **PA279CV**, **PA329CV**, **PA329C**, **PA32UCG**, **PA278CV**, **PA348CGV**
- **ROG Swift & Strix Series**:
  - **PG32UCDM** (4K OLED), **PG27AQDM**, **PG42UQ**, **XG27UCDMG**

### 6. Philips, EIZO, ViewSonic, MSI, & Lenovo
- **Philips**: Brilliance 279P1, 329P1H, 499P9H, Evnia gaming series
- **MSI**: Modern MD271UL, MAG 321UPX QD-OLED, MPG 321URX
- **ViewSonic**: ColorPro VP2786-4K, VP3268a-4K, VP2776
- **Lenovo**: ThinkVision P27u-20, P32u-10, P40w-20
- **EIZO**: ColorEdge & FlexScan USB-C series

---

## 🔌 Connection & Port Compatibility

| Connection Method | Status | Notes |
| :--- | :---: | :--- |
| **Thunderbolt 3 / 4 / 5** |  **Supported** | Full native hardware DDC/CI communication. Recommended. |
| **USB4 / USB-C (DP Alt Mode)** |  **Supported** | Full native hardware DDC/CI communication. |
| **DisplayPort** (via USB-C to DP) |  **Supported** | Full native hardware DDC/CI communication. |
| **HDMI 2.1** (M2 Pro/Max, M3, M4) |  **Supported** | Supported on Apple Silicon chips with modern HDMI 2.1 controllers. |
| **Built-in HDMI** (Base M1 / M2) | ⚠️ **Limited** | Apple restricts DDC pass-through on base M1/M2 built-in HDMI ports. Use USB-C instead. |

> **Important**: Ensure **DDC/CI** is toggled to **ON** in your monitor's built-in On-Screen Display (OSD) settings menu (typically found under *Menu -> General* or *Picture Settings -> DDC/CI*).

---

## 📦 Installation & Setup

### Prerequisites
- macOS 13.0 (Ventura) or newer (Sonoma, Sequoia, and macOS 27+ fully supported).
- Apple Silicon Mac (M1, M2, M3, M4 series).
- Monitor connected via Thunderbolt, USB4, or USB-C (DisplayPort Alt Mode).

### 1. One-Step Automated Setup & Build
Clone the repo and run the automated setup script, which validates developer tools, compiles the App and CLI, generates the DMG installer, and tests monitor communication:
```bash
git clone https://github.com/ajeygore/LG-Controls.git
cd LG-Controls

# One-step automated check, build, and DMG packaging
make setup
```

### 2. Install to Applications & Path
```bash
# Installs the app to /Applications and symlinks the CLI to /opt/homebrew/bin
make install
```

### 3. Build DMG Installer Package
To build a standalone `.dmg` installer for distribution:
```bash
make dmg
# Generates build/LG-Control.dmg (ready to drag-and-drop into Applications)
```

### 4. Launch App
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
- **Transport**: Communicates directly through Apple's `IOAVServiceWriteI2C` and `IOAVServiceReadI2C` APIs without spawning sub-processes. Supports standard DDC chip address `0x37` and MCDP29XX bridge address `0xB7`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
