import AppKit
import CoreGraphics

final class MediaKeyController {
    static let shared = MediaKeyController()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private weak var viewModel: MonitorViewModel?
    private(set) var isEnabled: Bool = false
    
    private init() {}
    
    func start(with viewModel: MonitorViewModel) {
        self.viewModel = viewModel
        guard Self.isAccessibilityTrusted() else {
            print("⚠️ Accessibility permission not granted for MediaKeyController")
            return
        }
        setupEventTap()
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        eventTap = nil
        isEnabled = false
    }
    
    static func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    private func setupEventTap() {
        stop()
        
        let mask = CGEventMask(1 << 14) // NX_SYSDEFINED
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let controller = Unmanaged<MediaKeyController>.fromOpaque(refcon).takeUnretainedValue()
            return controller.handleEvent(proxy: proxy, type: type, event: event)
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: selfPtr
        ) else {
            print("❌ Failed to create CGEvent tap for media keys")
            return
        }
        
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        self.eventTap = tap
        self.runLoopSource = source
        self.isEnabled = true
        print("✅ MediaKeyController active: listening for brightness keys on mouse display")
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
        
        guard type.rawValue == 14 else {
            return Unmanaged.passRetained(event)
        }
        
        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else {
            return Unmanaged.passRetained(event)
        }
        
        let data1 = nsEvent.data1
        let keyCode = Int((data1 & 0xFFFF0000) >> 16)
        let keyFlags = (data1 & 0x0000FFFF)
        let keyState = (keyFlags & 0xFF00) >> 8
        let isDown = (keyState == 0x0A)
        
        // Key codes:
        // 2 = Brightness Up, 3 = Brightness Down
        // 0 = Volume Up, 1 = Volume Down, 7 = Mute
        let isBrightnessKey = (keyCode == 2 || keyCode == 3)
        let isVolumeKey = (keyCode == 0 || keyCode == 1 || keyCode == 7)
        
        guard isBrightnessKey || isVolumeKey else {
            return Unmanaged.passRetained(event)
        }
        
        // Find which screen currently contains the mouse pointer
        let mouseLoc = NSEvent.mouseLocation
        guard let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) else {
            return Unmanaged.passRetained(event)
        }
        
        let screenNumber = activeScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
        
        // Check if the screen with mouse is an external display supported by our DDC manager
        let allDisplays = DDCManager.shared().getDisplays()
        guard let targetDisplay = allDisplays.first(where: { $0.displayID == screenNumber && $0.isExternal }) else {
            // Mouse is on built-in screen or non-DDC screen: let macOS handle it natively!
            return Unmanaged.passRetained(event)
        }
        
        // If it's a key release (up), consume it so macOS doesn't get confused
        if !isDown {
            return nil
        }
        
        // Determine step size (Fine adjustment if Shift + Option is held)
        let flags = event.flags
        let isFine = flags.contains(.maskShift) && flags.contains(.maskAlternate)
        let step: Double = isFine ? 1.25 : 5.0
        
        if isBrightnessKey {
            let delta = (keyCode == 2) ? step : -step
            handleBrightnessChange(on: activeScreen, display: targetDisplay, delta: delta)
            return nil // Consume event! Prevents macOS from modifying built-in screen.
        } else if isVolumeKey {
            if keyCode == 7 {
                handleMuteToggle(on: activeScreen, display: targetDisplay)
            } else {
                let delta = (keyCode == 0) ? step : -step
                handleVolumeChange(on: activeScreen, display: targetDisplay, delta: delta)
            }
            return nil // Consume event!
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func handleBrightnessChange(on screen: NSScreen, display: DDCDisplay, delta: Double) {
        Task { @MainActor in
            guard let vm = self.viewModel else { return }
            
            // If the user is on the display currently selected in the UI:
            if vm.selectedDisplay?.displayID == display.displayID {
                vm.adjustBrightness(by: delta)
                OSDController.shared.show(
                    on: screen,
                    type: .brightness,
                    value: vm.brightness,
                    monitorName: display.name
                )
            } else {
                // Adjust for this specific display
                let current = Double(DDCManager.shared().getLuminance(display.index))
                let newBrightness = max(0, min(100, (current >= 0 ? current : 50) + delta))
                _ = DDCManager.shared().setLuminance(Int(newBrightness.rounded()), forDisplay: display.index)
                OSDController.shared.show(
                    on: screen,
                    type: .brightness,
                    value: newBrightness,
                    monitorName: display.name
                )
            }
        }
    }
    
    private func handleVolumeChange(on screen: NSScreen, display: DDCDisplay, delta: Double) {
        Task { @MainActor in
            guard let vm = self.viewModel else { return }
            
            if vm.selectedDisplay?.displayID == display.displayID {
                vm.adjustVolume(by: delta)
                OSDController.shared.show(
                    on: screen,
                    type: .volume,
                    value: vm.volume,
                    monitorName: display.name
                )
            } else {
                let current = Double(DDCManager.shared().getVolume(display.index))
                let newVolume = max(0, min(100, (current >= 0 ? current : 30) + delta))
                _ = DDCManager.shared().setVolume(Int(newVolume.rounded()), forDisplay: display.index)
                OSDController.shared.show(
                    on: screen,
                    type: .volume,
                    value: newVolume,
                    monitorName: display.name
                )
            }
        }
    }
    
    private func handleMuteToggle(on screen: NSScreen, display: DDCDisplay) {
        Task { @MainActor in
            guard let vm = self.viewModel else { return }
            if vm.selectedDisplay?.displayID == display.displayID {
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
}
