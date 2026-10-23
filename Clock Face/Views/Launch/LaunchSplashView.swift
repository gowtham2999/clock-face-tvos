import SwiftUI

/// The opening moment: on the static launch colour, a dial draws itself, its twelve
/// marks arrive in turn, the hands sweep up to the real time, and the wordmark
/// settles in beneath — then everything dissolves into the app. About 2.5 seconds;
/// a quick fade with Reduce Motion on.
struct LaunchSplashView: View {
    let onFinished: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var ringProgress: CGFloat = 0
    @State private var marksShown = 0
    @State private var handsSet = false
    @State private var showsWordmark = false
    @State private var isLeaving = false

    /// Where the hands come to rest: the time when the app opened.
    private let angles = ClockAngles(date: .now)
    private let dialSize: CGFloat = 260

    var body: some View {
        ZStack {
            settings.theme.background
                .ignoresSafeArea()

            VStack(spacing: 64) {
                dial
                wordmark
            }
            .scaleEffect(isLeaving ? 1.1 : 1)
            .blur(radius: isLeaving ? 12 : 0)
        }
        .opacity(isLeaving ? 0 : 1)
        .foregroundStyle(Color.ink)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await play() }
    }

    // MARK: Dial

    private var dial: some View {
        let radius = dialSize / 2
        let accent = settings.color(for: .analogClassic)?.primary ?? .red

        return ZStack {
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.ink.opacity(0.2), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            ForEach(0..<12, id: \.self) { index in
                let isQuarter = index % 3 == 0
                Capsule()
                    .fill(Color.ink.opacity(isQuarter ? 0.9 : 0.4))
                    .frame(width: isQuarter ? 6 : 4, height: isQuarter ? 26 : 16)
                    .offset(y: -radius + (isQuarter ? 30 : 25))
                    .rotationEffect(.degrees(Double(index) * 30))
                    .opacity(index < marksShown ? 1 : 0)
                    .scaleEffect(index < marksShown ? 1 : 0.6)
            }

            hand(length: radius * 0.48, width: 10, angle: handsSet ? angles.hour : 0)
            hand(length: radius * 0.72, width: 8, angle: handsSet ? angles.minute : 0)

            // The second hand makes one full lap before settling on the current second.
            Capsule()
                .fill(accent)
                .frame(width: 3, height: radius * 0.92)
                .offset(y: -radius * 0.32)
                .rotationEffect(.degrees(handsSet ? 360 + angles.second : 0))
                .opacity(handsSet ? 1 : 0)

            Circle()
                .fill(accent)
                .frame(width: 14, height: 14)
                .scaleEffect(marksShown > 0 ? 1 : 0)
        }
        .frame(width: dialSize, height: dialSize)
    }

    private func hand(length: CGFloat, width: CGFloat, angle: Double) -> some View {
        Capsule()
            .fill(Color.ink)
            .frame(width: width, height: length)
            .offset(y: -length / 2 + width / 2)
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.25), radius: 6)
    }

    // MARK: Wordmark

    private var wordmark: some View {
        Text("\(Text("Clock").fontWeight(.light)) \(Text("Form").fontWeight(.semibold))")
            .font(.system(size: 64))
            .tracking(1)
            .opacity(showsWordmark ? 1 : 0)
            .offset(y: showsWordmark ? 0 : 18)
            .blur(radius: showsWordmark ? 0 : 6)
    }

    // MARK: Sequence

    private func play() async {
        if reduceMotion {
            ringProgress = 1
            marksShown = 12
            handsSet = true
            showsWordmark = true
            try? await Task.sleep(for: .seconds(1))
            withAnimation(.easeInOut(duration: 0.4)) { isLeaving = true }
            try? await Task.sleep(for: .seconds(0.4))
            onFinished()
            return
        }

        withAnimation(.easeInOut(duration: 0.9)) { ringProgress = 1 }
        for index in 1...12 {
            try? await Task.sleep(for: .milliseconds(55))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { marksShown = index }
        }

        withAnimation(.spring(response: 1.1, dampingFraction: 0.85)) { handsSet = true }
        try? await Task.sleep(for: .seconds(0.45))
        withAnimation(.easeOut(duration: 0.7)) { showsWordmark = true }

        try? await Task.sleep(for: .seconds(1.2))
        withAnimation(.easeIn(duration: 0.5)) { isLeaving = true }
        try? await Task.sleep(for: .seconds(0.5))
        onFinished()
    }
}

#Preview {
    LaunchSplashView {}
        .environment(AppSettings())
}
