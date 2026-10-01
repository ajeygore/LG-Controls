import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MonitorViewModel
    var onDetachWindow: (() -> Void)?
    var onQuit: (() -> Void)?
    
    // Theme Colors: Modern Off-White & Black / Graphite
    static let offWhite = Color(white: 0.95)
    static let mutedText = Color(white: 0.58)
    static let cardBackground = Color.white.opacity(0.06)
    static let cardBorder = Color.white.opacity(0.10)
    static let trackBackground = Color.white.opacity(0.12)
    static let pillActiveBg = Color(white: 0.95)
    static let pillActiveText = Color(white: 0.08)
    
    var body: some View {
        VStack(spacing: 14) {
            // Header: Display Selector, Status & Refresh
            headerView
            
            Rectangle()
                .fill(Self.cardBorder)
                .frame(height: 1)
                .padding(.horizontal, 2)
            
            if !viewModel.isConnected {
                noDisplayView
            } else {
                // Brightness Control Card
                ModernControlCard(
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
                ModernControlCard(
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
                ModernVolumeCard(viewModel: viewModel)
                
                Rectangle()
                    .fill(Self.cardBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 2)
                
                // Quick Profiles / Modes
                profilesSection
            }
            
            Rectangle()
                .fill(Self.cardBorder)
                .frame(height: 1)
                .padding(.horizontal, 2)
            
            // Footer: Actions
            footerView
        }
        .padding(.top, 22)
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .frame(width: 360)
        .background(
            ZStack {
                Color(white: 0.11)
                VisualEffectView(material: .popover, blendingMode: .withinWindow)
            }
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: "display")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Self.offWhite)
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
                                .foregroundColor(Self.offWhite)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Self.mutedText)
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                } else {
                    Text(viewModel.selectedDisplay?.name ?? "LG Monitor")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Self.offWhite)
                }
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.yellow)
                        .frame(width: 6, height: 6)
                    Text(viewModel.isConnected ? "Hardware Connected" : "Connecting...")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Self.mutedText)
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.loadCurrentValues() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Self.cardBorder, lineWidth: 1))
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Self.offWhite)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                }
            }
            .buttonStyle(.plain)
            .help("Refresh hardware values")
        }
    }
    
    // MARK: - No Display View
    private var noDisplayView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Self.offWhite)
            Text("No Supported External Display")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Self.offWhite)
            Text("Ensure your LG monitor is connected via Thunderbolt or USB-C with DDC/CI enabled in its OSD menu.")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(Self.mutedText)
                .padding(.horizontal, 10)
            
            Button("Scan Again") {
                viewModel.refreshDisplays()
            }
            .buttonStyle(.borderedProminent)
            .tint(Self.offWhite)
            .foregroundColor(.black)
            .font(.system(size: 11, weight: .semibold))
            .padding(.top, 4)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Profiles Section
    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROFILES")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(Self.mutedText)
                .tracking(0.8)
            
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
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Self.mutedText)
                }
                .buttonStyle(.plain)
                .help("Open as floating window")
            }
            
            Spacer()
            
            if let onQuit = onQuit {
                Button(action: onQuit) {
                    Text("Quit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Self.mutedText)
                }
                .buttonStyle(.plain)
                .help("Quit LG Control")
            }
        }
    }
}

// MARK: - Modern Control Card
struct ModernControlCard: View {
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ContentView.offWhite)
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ContentView.offWhite)
                }
                
                Spacer()
                
                Text("\(Int(value.rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(ContentView.offWhite)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(ContentView.cardBorder, lineWidth: 1))
            }
            
            // Slider Row with Steppers
            HStack(spacing: 10) {
                StepperButton(icon: "minus", action: onDecrement)
                
                Slider(value: $value, in: 0...100, step: 1)
                    .tint(ContentView.offWhite)
                
                StepperButton(icon: "plus", action: onIncrement)
            }
            
            // Preset Pills
            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { p in
                    let isSelected = Int(value.rounded()) == p
                    Button(action: { value = Double(p) }) {
                        Text("\(p)%")
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(isSelected ? ContentView.pillActiveBg : Color.white.opacity(0.05))
                            .foregroundColor(isSelected ? ContentView.pillActiveText : ContentView.mutedText)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isSelected ? Color.clear : ContentView.cardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(ContentView.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ContentView.cardBorder, lineWidth: 1))
    }
}

// MARK: - Modern Volume Card
struct ModernVolumeCard: View {
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ContentView.offWhite)
                    Text("Volume")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ContentView.offWhite)
                }
                
                Spacer()
                
                // Mute button
                Button(action: { viewModel.toggleMute() }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(viewModel.isMuted ? "MUTED" : "MUTE")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(viewModel.isMuted ? ContentView.pillActiveBg : Color.white.opacity(0.08))
                    .foregroundColor(viewModel.isMuted ? ContentView.pillActiveText : ContentView.offWhite)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(viewModel.isMuted ? Color.clear : ContentView.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Text("\(Int(viewModel.volume.rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(ContentView.offWhite)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(ContentView.cardBorder, lineWidth: 1))
            }
            
            // Slider Row with Steppers
            HStack(spacing: 10) {
                StepperButton(icon: "minus", action: { viewModel.adjustVolume(by: -5) })
                
                Slider(
                    value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolumeValue($0) }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(ContentView.offWhite)
                .disabled(viewModel.isMuted)
                .opacity(viewModel.isMuted ? 0.4 : 1.0)
                
                StepperButton(icon: "plus", action: { viewModel.adjustVolume(by: 5) })
            }
            
            // Preset Pills
            HStack(spacing: 6) {
                ForEach([0, 25, 50, 75], id: \.self) { p in
                    let isSelected = Int(viewModel.volume.rounded()) == p
                    Button(action: { viewModel.setVolumeValue(Double(p)) }) {
                        Text("\(p)%")
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(isSelected ? ContentView.pillActiveBg : Color.white.opacity(0.05))
                            .foregroundColor(isSelected ? ContentView.pillActiveText : ContentView.mutedText)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isSelected ? Color.clear : ContentView.cardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(ContentView.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ContentView.cardBorder, lineWidth: 1))
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
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(ContentView.cardBorder, lineWidth: 1))
                
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ContentView.offWhite)
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
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.06))
            .foregroundColor(ContentView.offWhite)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(ContentView.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vibrant background material
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
