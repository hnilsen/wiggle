import AppKit
import ApplicationServices
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings.shared
    private lazy var wiggler = Wiggler(settings: settings)

    private var statusItem: NSStatusItem!
    private var animationTimer: Timer?
    private var phase: CGFloat = 0
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Wiggle: click to toggle, right-click for menu"
        }

        settings.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in self?.updateIcon(enabled: enabled) }
            .store(in: &cancellables)

        _ = wiggler
        promptForAccessibilityIfNeeded()
    }

    // MARK: - Status item

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if wantsMenu {
            statusItem.menu = buildMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil // so the next left-click toggles again
        } else {
            settings.isEnabled.toggle()
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let status: String
        if settings.isEnabled, let next = wiggler.nextWiggle {
            status = "Wiggling, next in \(formatDuration(max(0, next.timeIntervalSinceNow)))"
        } else {
            status = settings.isEnabled ? "Wiggling" : "Resting"
        }
        menu.addItem(NSMenuItem(title: status, action: nil, keyEquivalent: ""))

        let toggle = NSMenuItem(title: settings.isEnabled ? "Turn Off" : "Turn On",
                                action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        if !AXIsProcessTrusted() {
            menu.addItem(.separator())
            let ax = NSMenuItem(title: "Grant Accessibility Permission…",
                                action: #selector(openAccessibilitySettings), keyEquivalent: "")
            ax.target = self
            menu.addItem(ax)
        }

        menu.addItem(.separator())
        settings.refreshLaunchAtLogin()
        let login = NSMenuItem(title: "Start at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = settings.launchAtLogin ? .on : .off
        menu.addItem(login)
        let prefs =NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)
        menu.addItem(NSMenuItem(title: "Quit Wiggle",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc private func toggleEnabled() { settings.isEnabled.toggle() }

    @objc private func toggleLaunchAtLogin() { settings.launchAtLogin.toggle() }

    // MARK: - Icon animation

    private func updateIcon(enabled: Bool) {
        animationTimer?.invalidate()
        animationTimer = nil

        guard enabled else {
            statusItem.button?.image = WiggleIcon.image(phase: 0, amplitude: 0)
            statusItem.button?.appearsDisabled = true
            return
        }

        statusItem.button?.appearsDisabled = false
        let timer = Timer(timeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.phase += 0.45
            self.statusItem.button?.image = WiggleIcon.image(phase: self.phase, amplitude: 3)
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
        timer.fire()
    }

    // MARK: - Settings window

    @objc private func showSettings() {
        settings.refreshLaunchAtLogin()
        if settingsWindow == nil {
            let host = NSHostingController(rootView: SettingsView(settings: settings))
            let window = NSWindow(contentViewController: host)
            window.title = "Wiggle Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Accessibility

    /// Posting synthetic mouse events requires Accessibility permission.
    private func promptForAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
