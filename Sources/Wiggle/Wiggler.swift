import AppKit
import Combine

/// Keeps the screen awake in two ways while enabled:
/// 1. A display-sleep power assertion (like video players use). This blocks
///    the screen saver / display sleep directly and also opts the app out of
///    App Nap, so our timers fire on time.
/// 2. A 1px mouse nudge (and back) at a random moment within the configured
///    interval. This resets the HID idle timer, which also keeps apps like
///    Slack/Teams from showing you as away.
final class Wiggler {
    private(set) var nextWiggle: Date?

    private let settings: Settings
    private var timer: Timer?
    private var keepAwakeActivity: NSObjectProtocol?
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
        setKeepAwake(enabled)
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

    private func setKeepAwake(_ on: Bool) {
        if on, keepAwakeActivity == nil {
            keepAwakeActivity = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiated, .idleDisplaySleepDisabled],
                reason: "Wiggle is keeping the screen awake"
            )
        } else if !on, let activity = keepAwakeActivity {
            ProcessInfo.processInfo.endActivity(activity)
            keepAwakeActivity = nil
        }
    }

    func wiggle() {
        guard let origin = CGEvent(source: nil)?.location else { return }
        // Moving out of and back into a screen corner could trigger a hot
        // corner (e.g. "Start Screen Saver"), so leave the cursor alone there.
        guard !isInScreenCorner(origin) else { return }
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

    /// True if `point` (global display coordinates, top-left origin, as used by
    /// CGEvent) is within `margin` px of a corner of the display it is on.
    private func isInScreenCorner(_ point: CGPoint, margin: CGFloat = 4) -> Bool {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return false }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &displays, &count) == .success else { return false }

        for display in displays.prefix(Int(count)) {
            let bounds = CGDisplayBounds(display)
            guard bounds.insetBy(dx: -1, dy: -1).contains(point) else { continue }
            let nearVerticalEdge = point.x - bounds.minX < margin || bounds.maxX - point.x <= margin
            let nearHorizontalEdge = point.y - bounds.minY < margin || bounds.maxY - point.y <= margin
            if nearVerticalEdge && nearHorizontalEdge { return true }
        }
        return false
    }
}
