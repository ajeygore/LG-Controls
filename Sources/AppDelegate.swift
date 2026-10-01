import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var detachedWindow: NSWindow?
    private lazy var viewModel = MonitorViewModel()
    private var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "display", accessibilityDescription: "LG Monitor Control") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "🖥️"
            }
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func setupPopover() {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        
        let contentView = ContentView(
            viewModel: viewModel,
            onDetachWindow: { [weak self] in
                self?.detachToWindow()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        
        pop.contentViewController = NSHostingController(rootView: contentView)
        self.popover = pop
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu(button)
            return
        }
        
        if let pop = popover {
            if pop.isShown {
                closePopover(sender)
            } else {
                showPopover(button)
            }
        }
    }
    
    private func showPopover(_ button: NSStatusBarButton) {
        viewModel.loadCurrentValues()
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Listen for clicks outside popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePopover(nil)
            }
        }
    }
    
    private func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func showContextMenu(_ button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "LG Monitor Control", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Floating Window", action: #selector(openFloatingWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshValues), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func openFloatingWindow() {
        detachToWindow()
    }
    
    @objc private func refreshValues() {
        viewModel.loadCurrentValues()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func detachToWindow() {
        closePopover(nil)
        
        if let existing = detachedWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = ContentView(
            viewModel: viewModel,
            onDetachWindow: nil,
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "LG Monitor Control"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.detachedWindow = window
    }
}
