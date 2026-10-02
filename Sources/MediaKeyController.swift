import AppKit
import CoreGraphics
import Combine

final class MediaKeyController: ObservableObject {
    static let shared = MediaKeyController()
    
    @Published var isEnabled: Bool = false
    @Published var isTrusted: Bool = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapRunLoop: CFRunLoop?
    private let tapQueue = DispatchQueue(label: "com.user.LGControl.MediaKeyTap", qos: .userInteractive)
    private var permissionTimer: Timer?
    private weak var viewModel: MonitorViewModel?
    
    private init() {
        self.isTrusted = Self.isAccessibilityTrusted()
    }
    
    func start(with viewModel: MonitorViewModel) {
        self.viewModel = viewModel
        self.isTrusted = Self.isAccessibilityTrusted()
        
        if self.isTrusted {
            NSLog("[LGControl] Accessibility is trusted at launch. Setting up event tap.")
            setupEventTap()
        } else {
            NSLog("[LGControl] Accessibility not yet trusted at launch. Silently polling in background.")
            startPermissionPolling()
        }
    }
    
    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            if let runLoop = tapRunLoop {
                CFRunLoopRemoveSource(runLoop, source, .commonModes)
            }
            runLoopSource = nil
        }
        if let runLoop = tapRunLoop {
            CFRunLoopStop(runLoop)
            tapRunLoop = nil
        }
        eventTap = nil
        
        Task { @MainActor in
            self.isEnabled = false
        }
    }
    
    static func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    static func openAccessibilitySettings() {
        requestAccessibilityPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Self.isAccessibilityTrusted() {
                self.permissionTimer?.invalidate()
                self.permissionTimer = nil
                Task { @MainActor in
                    self.isTrusted = true
                    self.setupEventTap()
                }
            }
        }
    }
    
    private func setupEventTap() {
        stop()
        
        // Listen to both KeyDown and NX_SYSDEFINED (media keys)
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << 14)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let controller = Unmanaged<MediaKeyController>.fromOpaque(refcon).takeUnretainedValue()
            return controller.handleEvent(proxy: proxy, type: type, event: event)
        }
        
        var tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: selfPtr
        )
        
        if tap == nil {
            NSLog("[LGControl] .cgSessionEventTap unavailable, falling back to .cghidEventTap...")
            tap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: callback,
                userInfo: selfPtr
            )
        }
        
        guard let finalTap = tap else {
            NSLog("[LGControl] ❌ Failed to create CGEvent tap for media keys")
            return
        }
        
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, finalTap, 0) else {
            NSLog("[LGControl] ❌ Failed to create run loop source for media keys")
            return
        }
        
        self.eventTap = finalTap
        self.runLoopSource = source
        
        // Run event tap on dedicated user-interactive queue to prevent UI stalls
        tapQueue.async { [weak self] in
            guard let self = self else { return }
            self.tapRunLoop = CFRunLoopGetCurrent()
            CFRunLoopAddSource(self.tapRunLoop, source, .commonModes)
            CGEvent.tapEnable(tap: finalTap, enable: true)
            
            Task { @MainActor [weak self] in
                self?.isEnabled = true
                self?.isTrusted = true
                NSLog("[LGControl] ✅ MediaKeyController active: listening for brightness keys on mouse display")
            }
            
            CFRunLoopRun()
        }
    }
    
    fileprivate func reEnableTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    fileprivate func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle timeout / auto-reenable
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            reEnableTap()
            return nil
        }
        
        var isBrightnessUp = false
        var isBrightnessDown = false
        var isVolumeUp = false
        var isVolumeDown = false
        var isMute = false
        var isKeyDown = false
        
        if type.rawValue == 14 { // NX_SYSDEFINED
            guard let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else {
                return Unmanaged.passUnretained(event)
            }
            
            let data1 = nsEvent.data1
            let keyCode = Int((data1 & 0xFFFF0000) >> 16)
            let keyFlags = (data1 & 0x0000FFFF)
            let keyState = (keyFlags & 0xFF00) >> 8
            isKeyDown = (keyState == 0x0A)
            
            switch keyCode {
            case 2: // NX_KEYTYPE_BRIGHTNESS_UP
                isBrightnessUp = true
            case 3: // NX_KEYTYPE_BRIGHTNESS_DOWN
                isBrightnessDown = true
            case 0: // NX_KEYTYPE_SOUND_UP
                isVolumeUp = true
            case 1: // NX_KEYTYPE_SOUND_DOWN
                isVolumeDown = true
            case 7: // NX_KEYTYPE_MUTE
                isMute = true
            default:
                return Unmanaged.passUnretained(event)
            }
        } else if type == .keyDown {
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            isKeyDown = true
            
            switch code {
            case 144, 113, 120: // Brightness Up (Media key 144, F15 113, F2 120)
                isBrightnessUp = true
            case 145, 107, 122: // Brightness Down (Media key 145, F14 107, F1 122)
                isBrightnessDown = true
            case 111: // Sound Up (F12)
                isVolumeUp = true
            case 103: // Sound Down (F11)
                isVolumeDown = true
            case 109: // Mute (F10)
                isMute = true
            default:
                return Unmanaged.passUnretained(event)
            }
        } else {
            return Unmanaged.passUnretained(event)
        }
        
        guard isBrightnessUp || isBrightnessDown || isVolumeUp || isVolumeDown || isMute else {
            return Unmanaged.passUnretained(event)
        }
        
        // Find which screen currently contains the mouse pointer
        let mouseLoc = NSEvent.mouseLocation
        let screens = NSScreen.screens
        guard let mouseScreen = screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main else {
            return Unmanaged.passUnretained(event)
        }
        
        let allDisplays = DDCManager.shared().getDisplays()
        let mouseDisplay = allDisplays.first(where: { $0.displayID == Self.displayID(of: mouseScreen) && $0.isExternal })
        
        let activeScreen: NSScreen
        let targetDisplay: DDCDisplay
        if isVolumeUp || isVolumeDown || isMute {
            // Volume follows the active sound output, not the cursor. Only drive DDC volume
            // when sound is playing through a monitor; otherwise let macOS handle it natively
            // (built-in speakers, wired/Bluetooth headphones, AirPlay, ...).
            guard let audioDisplay = AudioOutput.outputDisplay(among: allDisplays, fallback: mouseDisplay) else {
                return Unmanaged.passUnretained(event)
            }
            targetDisplay = audioDisplay
            activeScreen = screens.first(where: { Self.displayID(of: $0) == audioDisplay.displayID }) ?? mouseScreen
        } else {
            // Brightness follows the cursor. Built-in or non-DDC screen: let macOS handle it natively!
            guard let mouseDisplay = mouseDisplay else {
                return Unmanaged.passUnretained(event)
            }
            targetDisplay = mouseDisplay
            activeScreen = mouseScreen
        }
        
        // If it's a key release (up), consume it so macOS doesn't get confused
        if !isKeyDown {
            return nil
        }
        
        // Determine step size (Fine adjustment if Shift + Option is held)
        let flags = event.flags
        let isFine = flags.contains(.maskShift) && flags.contains(.maskAlternate)
        let step: Double = isFine ? 1.25 : 5.0
        
        if isBrightnessUp {
            handleBrightnessChange(on: activeScreen, display: targetDisplay, delta: step)
            return nil // Consume event! Prevents macOS from modifying built-in screen.
        } else if isBrightnessDown {
            handleBrightnessChange(on: activeScreen, display: targetDisplay, delta: -step)
            return nil // Consume event!
        } else if isVolumeUp {
            handleVolumeChange(on: activeScreen, display: targetDisplay, delta: step)
            return nil // Consume event!
        } else if isVolumeDown {
            handleVolumeChange(on: activeScreen, display: targetDisplay, delta: -step)
            return nil // Consume event!
        } else if isMute {
            handleMuteToggle(on: activeScreen, display: targetDisplay)
            return nil // Consume event!
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private static func displayID(of screen: NSScreen) -> CGDirectDisplayID {
        return screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    }
    
    private func handleBrightnessChange(on screen: NSScreen, display: DDCDisplay, delta: Double) {
        Task { @MainActor in
            guard let vm = self.viewModel else { return }
            
            if vm.selectedDisplay?.displayID != display.displayID {
                vm.selectDisplay(display)
            }
            
            vm.adjustBrightness(by: delta)
            OSDController.shared.show(
                on: screen,
                type: .brightness,
                value: vm.brightness,
                monitorName: display.name
            )
        }
    }
    
    private func handleVolumeChange(on screen: NSScreen, display: DDCDisplay, delta: Double) {
        Task { @MainActor in
            guard let vm = self.viewModel else { return }
            
            if vm.selectedDisplay?.displayID != display.displayID {
                vm.selectDisplay(display)
            }
            
            vm.adjustVolume(by: delta)
            OSDController.shared.show(
                on: screen,
                type: .volume,
                value: vm.volume,
                monitorName: display.name
            )
        }
    }
    
    private func handleMuteToggle(on screen: NSScreen, display: DDCDisplay) {
        Task { @MainActor in
            guard let vm = self.viewModel else { return }
            
            if vm.selectedDisplay?.displayID != display.displayID {
                vm.selectDisplay(display)
            }
            
            vm.toggleMute()
            OSDController.shared.show(
                on: screen,
                type: .volume,
                value: vm.isMuted ? 0 : vm.volume,
                monitorName: display.name
            )
        }
    }
}
