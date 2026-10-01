import Foundation
import Combine
import SwiftUI

@MainActor
final class MonitorViewModel: ObservableObject {
    @Published var displays: [DDCDisplay] = []
    @Published var selectedDisplay: DDCDisplay?
    
    @Published var brightness: Double = 50
    @Published var contrast: Double = 50
    @Published var volume: Double = 50
    @Published var isMuted: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = ""
    
    // Launch at login status
    @Published var launchAtLogin: Bool = false

    private let manager = DDCManager.shared()
    
    // Debounce subjects for smooth sliding
    private let brightnessSubject = PassthroughSubject<Double, Never>()
    private let contrastSubject = PassthroughSubject<Double, Never>()
    private let volumeSubject = PassthroughSubject<Double, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupDebouncing()
        refreshDisplays()
    }
    
    private func setupDebouncing() {
        brightnessSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(70), scheduler: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] val in
                guard let self = self, let display = self.selectedDisplay else { return }
                _ = self.manager.setLuminance(Int(val.rounded()), forDisplay: display.index)
            }
            .store(in: &cancellables)
        
        contrastSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(70), scheduler: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] val in
                guard let self = self, let display = self.selectedDisplay else { return }
                _ = self.manager.setContrast(Int(val.rounded()), forDisplay: display.index)
            }
            .store(in: &cancellables)
            
        volumeSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(70), scheduler: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] val in
                guard let self = self, let display = self.selectedDisplay else { return }
                _ = self.manager.setVolume(Int(val.rounded()), forDisplay: display.index)
            }
            .store(in: &cancellables)
    }
    
    func refreshDisplays() {
        isLoading = true
        statusMessage = "Scanning for displays..."
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let allDisplays = await self.manager.getDisplays()
            
            await MainActor.run {
                self.displays = allDisplays
                // Prefer external displays (like LG ULTRAFINE)
                if let external = allDisplays.first(where: { $0.isExternal }) {
                    self.selectedDisplay = external
                    self.isConnected = true
                    self.statusMessage = "Connected to \(external.name)"
                } else if let first = allDisplays.first {
                    self.selectedDisplay = first
                    self.isConnected = false
                    self.statusMessage = "No external DDC monitor detected"
                } else {
                    self.selectedDisplay = nil
                    self.isConnected = false
                    self.statusMessage = "No displays found"
                }
                
                self.loadCurrentValues()
            }
        }
    }
    
    func selectDisplay(_ display: DDCDisplay) {
        selectedDisplay = display
        isConnected = display.isExternal
        loadCurrentValues()
    }
    
    func loadCurrentValues() {
        guard let display = selectedDisplay, display.isExternal else {
            isLoading = false
            return
        }
        
        isLoading = true
        let displayIndex = display.index
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let lum = await self.manager.getLuminance(displayIndex)
            let con = await self.manager.getContrast(displayIndex)
            let vol = await self.manager.getVolume(displayIndex)
            let muted = await self.manager.getMute(displayIndex)
            
            await MainActor.run {
                if lum >= 0 { self.brightness = Double(lum) }
                if con >= 0 { self.contrast = Double(con) }
                if vol >= 0 { self.volume = Double(vol) }
                self.isMuted = muted
                self.isLoading = false
            }
        }
    }
    
    // User triggered changes
    func setBrightnessValue(_ val: Double) {
        let clamped = max(0, min(100, val))
        brightness = clamped
        brightnessSubject.send(clamped)
    }
    
    func setContrastValue(_ val: Double) {
        let clamped = max(0, min(100, val))
        contrast = clamped
        contrastSubject.send(clamped)
    }
    
    func setVolumeValue(_ val: Double) {
        let clamped = max(0, min(100, val))
        volume = clamped
        volumeSubject.send(clamped)
    }
    
    func adjustBrightness(by delta: Double) {
        setBrightnessValue(brightness + delta)
    }
    
    func adjustContrast(by delta: Double) {
        setContrastValue(contrast + delta)
    }
    
    func adjustVolume(by delta: Double) {
        setVolumeValue(volume + delta)
    }
    
    func toggleMute() {
        guard let display = selectedDisplay, display.isExternal else { return }
        let newMute = !isMuted
        isMuted = newMute
        let displayIndex = display.index
        Task.detached(priority: .userInitiated) { [weak self] in
            _ = await self?.manager.setMute(newMute, forDisplay: displayIndex)
        }
    }
    
    // Presets
    func applyProfile(name: String, targetBrightness: Double, targetContrast: Double) {
        setBrightnessValue(targetBrightness)
        setContrastValue(targetContrast)
        statusMessage = "Applied \(name) preset"
    }
}
