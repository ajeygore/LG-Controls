import AppKit
import SwiftUI

enum OSDType {
    case brightness
    case volume
}

@MainActor
final class OSDController {
    static let shared = OSDController()
    
    private var window: NSPanel?
    private var dismissTimer: Timer?
    private let osdState = OSDState()
    
    private init() {
        setupWindow()
    }
    
    private func setupWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        
        let hostingView = NSHostingView(rootView: OSDView(state: osdState))
        panel.contentView = hostingView
        self.window = panel
    }
    
    func show(on screen: NSScreen, type: OSDType, value: Double, monitorName: String) {
        osdState.type = type
        osdState.value = max(0, min(100, value))
        osdState.monitorName = monitorName
        
        guard let panel = window else { return }
        
        // Position at bottom center of the target screen
        let screenFrame = screen.frame
        let windowWidth: CGFloat = 200
        let x = screenFrame.midX - windowWidth / 2
        let y = screenFrame.minY + screenFrame.height * 0.14
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.alphaValue = 1.0
        panel.orderFrontRegardless()
        
        // Reset timer
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fadeOut()
            }
        }
    }
    
    private func fadeOut() {
        guard let panel = window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            panel.animator().alphaValue = 0.0
        }, completionHandler: {
            if panel.alphaValue == 0 {
                panel.orderOut(nil)
            }
        })
    }
}

final class OSDState: ObservableObject {
    @Published var type: OSDType = .brightness
    @Published var value: Double = 50
    @Published var monitorName: String = "Display"
}

struct OSDView: View {
    @ObservedObject var state: OSDState
    
    var iconName: String {
        switch state.type {
        case .brightness:
            if state.value < 33 {
                return "sun.min.fill"
            } else {
                return "sun.max.fill"
            }
        case .volume:
            if state.value == 0 {
                return "speaker.slash.fill"
            } else if state.value < 33 {
                return "speaker.wave.1.fill"
            } else if state.value < 66 {
                return "speaker.wave.2.fill"
            } else {
                return "speaker.wave.3.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Monitor Name Header
            Text(state.monitorName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer(minLength: 0)
            
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 52, weight: .light))
                .foregroundColor(.white)
                .frame(height: 56)
            
            Spacer(minLength: 0)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 7)
                    
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(Color.white)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(state.value / 100.0))), height: 7)
                }
            }
            .frame(height: 7)
            .padding(.horizontal, 14)
            
            // Percentage
            Text("\(Int(state.value.rounded()))%")
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundColor(Color.white.opacity(0.9))
        }
        .padding(18)
        .frame(width: 200, height: 200)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(0.4)
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

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
