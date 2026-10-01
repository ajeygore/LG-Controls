import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MonitorViewModel
    var onDetachWindow: (() -> Void)?
    var onQuit: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: Display Selector & Status
            headerView
            
            Divider()
            
            if !viewModel.isConnected {
                noDisplayView
            } else {
                // Brightness Control Card
                ControlCard(
                    title: "Brightness",
                    iconName: "sun.max.fill",
                    accentColor: .orange,
                    value: Binding(
                        get: { viewModel.brightness },
                        set: { viewModel.setBrightnessValue($0) }
                    ),
                    presets: [25, 50, 75, 100],
                    onDecrement: { viewModel.adjustBrightness(by: -5) },
                    onIncrement: { viewModel.adjustBrightness(by: 5) }
                )
                
                // Contrast Control Card
                ControlCard(
                    title: "Contrast",
                    iconName: "circle.lefthalf.filled",
                    accentColor: .teal,
                    value: Binding(
                        get: { viewModel.contrast },
                        set: { viewModel.setContrastValue($0) }
                    ),
                    presets: [50, 60, 70, 80],
                    onDecrement: { viewModel.adjustContrast(by: -5) },
                    onIncrement: { viewModel.adjustContrast(by: 5) }
                )
                
                // Volume Control Card
                VolumeControlCard(
                    viewModel: viewModel
                )
                
                Divider()
                
                // Quick Profiles / Modes
                profilesSection
            }
            
            Divider()
            
            // Footer: Actions
            footerView
        }
        .padding(18)
        .frame(width: 380)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "display")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.accentColor)
            
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
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                } else {
                    Text(viewModel.selectedDisplay?.name ?? "LG Monitor")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                    Text(viewModel.isConnected ? "DDC/CI Connected" : "Connecting...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.loadCurrentValues() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
            }
            .buttonStyle(.plain)
            .help("Refresh hardware values")
        }
    }
    
    // MARK: - No Display View
    private var noDisplayView: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            Text("No Supported External Display")
                .font(.headline)
            Text("Please ensure your LG monitor is connected via Thunderbolt, USB-C, or DisplayPort with DDC/CI enabled in monitor settings.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Scan Again") {
                viewModel.refreshDisplays()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Profiles Section
    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK PROFILES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ProfileButton(title: "Night", icon: "moon.fill", brightness: 20, contrast: 60, viewModel: viewModel)
                ProfileButton(title: "Read", icon: "book.fill", brightness: 40, contrast: 65, viewModel: viewModel)
                ProfileButton(title: "Day", icon: "sun.max.fill", brightness: 75, contrast: 70, viewModel: viewModel)
                ProfileButton(title: "Cinema", icon: "film.fill", brightness: 100, contrast: 80, viewModel: viewModel)
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
                        Text("Detach")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Open as floating window")
            }
            
            Spacer()
            
            if let onQuit = onQuit {
                Button(action: onQuit) {
                    Text("Quit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit LG Control")
            }
        }
    }
}

// MARK: - Subviews

struct ControlCard: View {
    let title: String
    let iconName: String
    let accentColor: Color
    @Binding var value: Double
    let presets: [Int]
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(title, systemImage: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                Text("\(Int(value.rounded()))%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(6)
            }
            
            HStack(spacing: 8) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.borderless)
                
                Slider(value: $value, in: 0...100, step: 1)
                    .tint(accentColor)
                
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.borderless)
            }
            
            // Preset pills
            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { p in
                    Button(action: { value = Double(p) }) {
                        Text("\(p)%")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Int(value.rounded()) == p ? accentColor.opacity(0.25) : Color.primary.opacity(0.05))
                            .foregroundColor(Int(value.rounded()) == p ? accentColor : .secondary)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }
}

struct VolumeControlCard: View {
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
        VStack(spacing: 8) {
            HStack {
                Label("Volume", systemImage: volumeIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.isMuted ? .red : .purple)
                
                Spacer()
                
                Button(action: { viewModel.toggleMute() }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        Text(viewModel.isMuted ? "Muted" : "Mute")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(viewModel.isMuted ? .white : .primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(viewModel.isMuted ? Color.red : Color.primary.opacity(0.08))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Text("\(Int(viewModel.volume.rounded()))%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(6)
            }
            
            HStack(spacing: 8) {
                Button(action: { viewModel.adjustVolume(by: -5) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.borderless)
                
                Slider(
                    value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolumeValue($0) }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(.purple)
                .disabled(viewModel.isMuted)
                
                Button(action: { viewModel.adjustVolume(by: 5) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.borderless)
            }
            
            // Preset pills
            HStack(spacing: 6) {
                ForEach([0, 25, 50, 75], id: \.self) { p in
                    Button(action: { viewModel.setVolumeValue(Double(p)) }) {
                        Text("\(p)%")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Int(viewModel.volume.rounded()) == p ? Color.purple.opacity(0.25) : Color.primary.opacity(0.05))
                            .foregroundColor(Int(viewModel.volume.rounded()) == p ? Color.purple : .secondary)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }
}

struct ProfileButton: View {
    let title: String
    let icon: String
    let brightness: Double
    let contrast: Double
    @ObservedObject var viewModel: MonitorViewModel
    
    var body: some View {
        Button(action: {
            viewModel.applyProfile(name: title, targetBrightness: brightness, targetContrast: contrast)
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// Vibrant background material
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
