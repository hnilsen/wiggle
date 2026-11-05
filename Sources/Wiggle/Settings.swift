import Foundation
import ServiceManagement

/// User preferences. Intervals are persisted in UserDefaults; the login item
/// state lives in macOS itself (SMAppService).
final class Settings: ObservableObject {
    static let shared = Settings()

    static let intervalRange: ClosedRange<Double> = 10...600 // seconds

    private let defaults = UserDefaults.standard

    /// Wiggling always starts OFF on launch (including at login) and is
    /// intentionally not persisted.
    @Published var isEnabled = false

    /// Start Wiggle automatically when the user logs in.
    @Published var launchAtLogin = Settings.loginItemIsEnabled {
        didSet {
            guard !isSyncingLoginItem, launchAtLogin != oldValue else { return }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Wiggle: failed to update login item: \(error)")
            }
            refreshLaunchAtLogin()
        }
    }

    private var isSyncingLoginItem = false

    private static var loginItemIsEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval: return true
        default: return false
        }
    }

    /// Re-reads the real login item state (the user may change it in
    /// System Settings → General → Login Items).
    func refreshLaunchAtLogin() {
        isSyncingLoginItem = true
        launchAtLogin = Settings.loginItemIsEnabled
        isSyncingLoginItem = false
    }

    /// Shortest time between wiggles, in seconds.
    @Published var minInterval: Double {
        didSet {
            if maxInterval < minInterval { maxInterval = minInterval }
            defaults.set(minInterval, forKey: Keys.minInterval)
        }
    }

    /// Longest time between wiggles, in seconds.
    @Published var maxInterval: Double {
        didSet {
            if minInterval > maxInterval { minInterval = maxInterval }
            defaults.set(maxInterval, forKey: Keys.maxInterval)
        }
    }

    private enum Keys {
        static let minInterval = "minInterval"
        static let maxInterval = "maxInterval"
    }

    private init() {
        defaults.register(defaults: [
            Keys.minInterval: 60.0,
            Keys.maxInterval: 120.0,
        ])
        minInterval = defaults.double(forKey: Keys.minInterval)
        maxInterval = defaults.double(forKey: Keys.maxInterval)
    }
}
