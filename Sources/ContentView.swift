import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MonitorViewModel
    @ObservedObject var mediaKeys = MediaKeyController.shared
    var onDetachWindow: (() -> Void)?
    var onQuit: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 14) {
            // Header: Display Selector, Status & Refresh
            headerView
            
            Divider()
                .opacity(0.6)
            
            if !viewModel.isConnected {
                noDisplayView
            } else {
                // Brightness Control Card
                AppleControlCard(
                    title: "Brightness",
                    iconName: "sun.max.fill",
                    value: Binding(
                        get: { viewModel.brightness },
                        set: { viewModel.setBrightnessValue($0) }
                    ),
                    presets: [25, 50, 75, 100],
                    onDecrement: { viewModel.adjustBrightness(by: -5) },
                    onIncrement: { viewModel.adjustBrightness(by: 5) }
                )
                
                // Contrast Control Card
                AppleControlCard(
                    title: "Contrast",
                    iconName: "circle.lefthalf.filled",
                    value: Binding(
                        get: { viewModel.contrast },
                        set: { viewModel.setContrastValue($0) }
                    ),
                    presets: [50, 60, 70, 80],
                    onDecrement: { viewModel.adjustContrast(by: -5) },
                    onIncrement: { viewModel.adjustContrast(by: 5) }
                )
                
                // Volume Control Card
                AppleVolumeCard(viewModel: viewModel)
                
                Divider()
                    .opacity(0.6)
                
                // Quick Profiles / Modes
                profilesSection
            }
            
            Divider()
                .opacity(0.6)
            
            // Footer: Actions
            footerView
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .frame(width: 340)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 30, height: 30)
                Image(systemName: "display")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.displays.count > 1 {
                    Menu {
                        ForEach(viewModel.displays, id: \.uuid) { display in
                            Button(action: { viewModel.selectDisplay(display) }) {
                                HStack {
                                    Text(display.name)
                                    if display.uuid == viewModel.selectedDisplay?.uuid {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedDisplay?.name ?? "Select Monitor")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                } else {
                    Text(viewModel.selectedDisplay?.name ?? "LG Monitor")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(viewModel.isConnected ? "Connected" : "Scanning...")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.loadCurrentValues() }) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5))
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.65)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .help("Refresh hardware values")
        }
    }
    
    // MARK: - No Display View
    private var noDisplayView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.secondary)
            Text("No Supported External Display")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            Text("Ensure your LG monitor is connected via Thunderbolt or USB-C with DDC/CI enabled in its OSD menu.")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
            
            Button("Scan Again") {
                viewModel.refreshDisplays()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.primary)
            .font(.system(size: 11, weight: .medium))
            .padding(.top, 4)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Profiles Section
    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROFILES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ProfilePill(title: "Night", icon: "moon.fill", brightness: 20, contrast: 60, viewModel: viewModel)
                ProfilePill(title: "Read", icon: "book.fill", brightness: 40, contrast: 65, viewModel: viewModel)
                ProfilePill(title: "Day", icon: "sun.max.fill", brightness: 75, contrast: 70, viewModel: viewModel)
                ProfilePill(title: "Max", icon: "bolt.fill", brightness: 100, contrast: 80, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack(spacing: 12) {
            if let onDetachWindow = onDetachWindow {
                Button(action: onDetachWindow) {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 11))
                        Text("Detach")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open as floating window")
            }
            
            Spacer()
            
            if mediaKeys.isTrusted {
                HStack(spacing: 5) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 10))
                    Text("F1/F2: Mouse Screen")
                        .font(.system(size: 10, weight: .regular))
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 5, height: 5)
                }
                .foregroundColor(.secondary)
                .help("Brightness keys (F1/F2) adjust whichever monitor your mouse is hovering over")
            } else {
                Button(action: {
                    MediaKeyController.openAccessibilitySettings()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("Enable F1/F2 Keys")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .help("Click to open System Settings > Privacy & Security > Accessibility and enable LG Control")
            }
            
            Spacer()
            
            if let onQuit = onQuit {
                Button(action: onQuit) {
                    Text("Quit")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit LG Control")
            }
        }
    }
}

// MARK: - Apple Control Card
struct AppleControlCard: View {
    let title: String
    let iconName: String
    @Binding var value: Double
    let presets: [Int]
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Label and Percentage Badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(Int(value.rounded()))%")
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5))
            }
            
            // Slider Row with Steppers
            HStack(spacing: 8) {
                StepperButton(icon: "minus", action: onDecrement)
                
                Slider(value: $value, in: 0...100, step: 1)
                    .tint(.primary)
                
                StepperButton(icon: "plus", action: onIncrement)
            }
            
            // Preset Pills
            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { p in
                    let isSelected = Int(value.rounded()) == p
                    Button(action: { value = Double(p) }) {
                        Text("\(p)%")
                            .font(.system(size: 10, weight: isSelected ? .semibold : .medium).monospacedDigit())
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(isSelected ? Color.primary : Color.primary.opacity(0.05))
                            .foregroundColor(isSelected ? Color(nsColor: .windowBackgroundColor) : Color.secondary)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(isSelected ? Color.clear : Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.65))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5))
    }
}

// MARK: - Apple Volume Card
struct AppleVolumeCard: View {
    @ObservedObject var viewModel: MonitorViewModel
    
    var volumeIcon: String {
        if viewModel.isMuted || viewModel.volume == 0 {
            return "speaker.slash.fill"
        } else if viewModel.volume < 33 {
            return "speaker.wave.1.fill"
        } else if viewModel.volume < 66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Label, Mute Toggle & Percentage Badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: volumeIcon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Text("Volume")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Mute button
                Button(action: { viewModel.toggleMute() }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text(viewModel.isMuted ? "Muted" : "Mute")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(viewModel.isMuted ? Color.primary : Color.primary.opacity(0.06))
                    .foregroundColor(viewModel.isMuted ? Color(nsColor: .windowBackgroundColor) : Color.primary)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(viewModel.isMuted ? Color.clear : Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                
                Text("\(Int(viewModel.volume.rounded()))%")
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5))
            }
            
            // Slider Row with Steppers
            HStack(spacing: 8) {
                StepperButton(icon: "minus", action: { viewModel.adjustVolume(by: -5) })
                
                Slider(
                    value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolumeValue($0) }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(.primary)
                .disabled(viewModel.isMuted)
                .opacity(viewModel.isMuted ? 0.35 : 1.0)
                
                StepperButton(icon: "plus", action: { viewModel.adjustVolume(by: 5) })
            }
            
            // Preset Pills
            HStack(spacing: 6) {
                ForEach([0, 25, 50, 75], id: \.self) { p in
                    let isSelected = Int(viewModel.volume.rounded()) == p
                    Button(action: { viewModel.setVolumeValue(Double(p)) }) {
                        Text("\(p)%")
                            .font(.system(size: 10, weight: isSelected ? .semibold : .medium).monospacedDigit())
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(isSelected ? Color.primary : Color.primary.opacity(0.05))
                            .foregroundColor(isSelected ? Color(nsColor: .windowBackgroundColor) : Color.secondary)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(isSelected ? Color.clear : Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.65))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5))
    }
}

// MARK: - Stepper Button
struct StepperButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(width: 20, height: 20)
                    .overlay(Circle().strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5))
                
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Pill
struct ProfilePill: View {
    let title: String
    let icon: String
    let brightness: Double
    let contrast: Double
    @ObservedObject var viewModel: MonitorViewModel
    
    var body: some View {
        Button(action: {
            viewModel.applyProfile(name: title, targetBrightness: brightness, targetContrast: contrast)
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.05))
            .foregroundColor(.primary)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}
