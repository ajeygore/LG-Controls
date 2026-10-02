import CoreAudio
import Foundation

/// Inspects the system's current default sound output device so volume keys
/// only drive monitor DDC volume when audio is actually playing through a monitor.
enum AudioOutput {
    struct Device {
        let name: String
        let transportType: UInt32
    }

    static func defaultOutputDevice() -> Device? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID) == noErr,
              deviceID != kAudioObjectUnknown else {
            return nil
        }

        var transport = UInt32(0)
        size = UInt32(MemoryLayout<UInt32>.size)
        address.mSelector = kAudioDevicePropertyTransportType
        _ = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transport)

        var cfName: Unmanaged<CFString>?
        size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        address.mSelector = kAudioObjectPropertyName
        var name = ""
        if AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &cfName) == noErr, let cfName = cfName {
            name = cfName.takeRetainedValue() as String
        }

        return Device(name: name, transportType: transport)
    }

    /// Returns the external DDC display whose audio device is the current default output,
    /// or nil if sound is going somewhere else (speakers, headphones, Bluetooth, AirPlay, ...).
    /// `fallback` is used when output is monitor audio (DisplayPort/HDMI) but no display name matches.
    static func outputDisplay(among displays: [DDCDisplay], fallback: DDCDisplay?) -> DDCDisplay? {
        guard let device = defaultOutputDevice() else { return nil }
        let externals = displays.filter { $0.isExternal }
        guard !externals.isEmpty else { return nil }

        let deviceName = device.name.lowercased()
        if !deviceName.isEmpty, let match = externals.first(where: { display in
            let displayName = display.name.lowercased()
            return !displayName.isEmpty && (deviceName.contains(displayName) || displayName.contains(deviceName))
        }) {
            return match
        }

        let isDisplayTransport = device.transportType == kAudioDeviceTransportTypeDisplayPort ||
            device.transportType == kAudioDeviceTransportTypeHDMI
        guard isDisplayTransport else { return nil }
        return fallback ?? (externals.count == 1 ? externals.first : nil)
    }
}
