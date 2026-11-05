import AppKit
import Combine

/// Nudges the mouse 1px (and back) at a random moment within the configured
/// interval. Synthetic HID events reset the system idle timer, so the screen
/// saver, display sleep and auto-lock never kick in.
final class Wiggler {
    private(set) var nextWiggle: Date?

    private let settings: Settings
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(settings: Settings) {
        self.settings = settings

        // @Published emits on willSet, so use the emitted values rather than
        // reading `settings` inside the sink.
        settings.$isEnabled
            .combineLatest(settings.$minInterval, settings.$maxInterval)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] enabled, min, max in
                self?.schedule(enabled: enabled, min: min, max: max)
            }
            .store(in: &cancellables)
    }

    private func schedule(enabled: Bool, min: Double, max: Double) {
        timer?.invalidate()
        timer = nil
        nextWiggle = nil
        guard enabled else { return }

        let delay = Double.random(in: min...Swift.max(min, max))
        let t = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.wiggle()
            self.schedule(enabled: self.settings.isEnabled,
                          min: self.settings.minInterval,
                          max: self.settings.maxInterval)
        }
        t.tolerance = 1
        RunLoop.main.add(t, forMode: .common) // keep firing while a menu is open
        timer = t
        nextWiggle = Date().addingTimeInterval(delay)
    }

    func wiggle() {
        guard let origin = CGEvent(source: nil)?.location else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let nudged = CGPoint(x: origin.x > 0 ? origin.x - 1 : origin.x + 1, y: origin.y)

        func move(to point: CGPoint) {
            CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                    mouseCursorPosition: point, mouseButton: .left)?
                .post(tap: .cghidEventTap)
        }

        move(to: nudged)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { move(to: origin) }
    }
}
