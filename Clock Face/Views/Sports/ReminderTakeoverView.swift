import SwiftUI

/// Full-screen alert shown while the app is open when a reminded session is
/// 15 minutes away. (tvOS doesn't allow third-party notification banners.)
struct ReminderTakeoverView: View {
    let reminder: Reminder
    let onDismiss: () -> Void

    @Environment(AppSettings.self) private var settings
    @State private var player = TickSoundPlayer()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [Color.racingRed.opacity(0.35), .clear], center: .top, startRadius: 0, endRadius: 900)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                Label("REMINDER", systemImage: "bell.fill")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color.racingRed)
                Text(reminder.eventName)
                    .font(.system(size: 64, weight: .bold))
                    .accessibilityIdentifier("reminderEvent")
                Text("\(reminder.seriesName) · \(reminder.sessionName)")
                    .font(.system(size: 30))
                    .opacity(0.7)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    countdown(at: context.date)
                }
                .padding(.vertical, 12)

                Button("Dismiss", action: onDismiss)
                    .accessibilityIdentifier("dismissReminder")
            }
            .foregroundStyle(.white)
        }
        .onAppear {
            if settings.chimeSource != .mute {
                player.chime(volume: settings.volume)
            }
        }
        .onExitCommand(perform: onDismiss)
    }

    @ViewBuilder
    private func countdown(at date: Date) -> some View {
        let remaining = Int(reminder.start.timeIntervalSince(date).rounded(.up))
        if remaining > 0 {
            VStack(spacing: 6) {
                Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                    .font(.system(size: 180, weight: .semibold).width(.compressed))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: remaining)
                Text("UNTIL START")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(2)
                    .opacity(0.6)
            }
        } else {
            Text("STARTING NOW")
                .font(.system(size: 120, weight: .semibold).width(.compressed))
                .foregroundStyle(Color.racingRed)
        }
    }
}
