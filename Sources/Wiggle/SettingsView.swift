import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Wiggle the mouse to keep the screen awake", isOn: $settings.isEnabled)

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Start Wiggle at login", isOn: $settings.launchAtLogin)
                Text("Wiggle always starts switched off. Click the worm to turn it on.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("At least \(formatDuration(settings.minInterval)) between wiggles")
                Slider(value: $settings.minInterval, in: Settings.intervalRange, step: 10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("At most \(formatDuration(settings.maxInterval)) between wiggles")
                Slider(value: $settings.maxInterval, in: Settings.intervalRange, step: 10)
            }

            Text("Each wiggle happens at a random moment in this range. Keep the maximum below your screen saver / display sleep timeout.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 360)
    }
}

func formatDuration(_ seconds: Double) -> String {
    let s = Int(seconds.rounded())
    switch (s / 60, s % 60) {
    case (0, let sec): return "\(sec)s"
    case (let min, 0): return "\(min) min"
    case (let min, let sec): return "\(min) min \(sec)s"
    }
}
