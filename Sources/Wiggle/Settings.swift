import Foundation

/// User preferences, persisted in UserDefaults.
final class Settings: ObservableObject {
    static let shared = Settings()

    static let intervalRange: ClosedRange<Double> = 10...600 // seconds

    private let defaults = UserDefaults.standard

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
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
        static let isEnabled = "isEnabled"
        static let minInterval = "minInterval"
        static let maxInterval = "maxInterval"
    }

    private init() {
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.minInterval: 60.0,
            Keys.maxInterval: 120.0,
        ])
        isEnabled = defaults.bool(forKey: Keys.isEnabled)
        minInterval = defaults.double(forKey: Keys.minInterval)
        maxInterval = defaults.double(forKey: Keys.maxInterval)
    }
}
