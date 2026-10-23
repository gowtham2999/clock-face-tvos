import SwiftUI
import UIKit

struct RootView: View {
    @State private var settings = AppSettings()
    @State private var weather = WeatherStore()
    @State private var schedule = F1ScheduleStore()
    @State private var reminders = ReminderStore()

    @State private var selectedTab: AppTab = .home
    @State private var isSettingsOpen = false
    @State private var isChromeVisible = true
    @State private var lastInteraction = Date()
    @State private var detailFace: WatchFaceType?
    @State private var activeReminder: Reminder?
    @State private var hasLaunched = false
    /// The animated intro plays once per launch, over the first screen.
    @State private var isShowingSplash = !UserDefaults.standard.bool(forKey: "skipLaunchAnimation")
    /// Set while zooming between the dashboard and the full-screen clock, so the
    /// clock arrives immersive (top bar hidden) and focus lands on the canvas.
    @State private var isZoomingBetweenHomeAndClock = false
    @FocusState private var isCanvasFocused: Bool

    @Environment(\.scenePhase) private var scenePhase

    /// Seconds of inactivity before the Home and Clock tabs hide the top bar: short while the
    /// user is just watching the clock, longer while focus is in the top bar itself.
    private let chromeTimeout: TimeInterval = 5
    private let chromeTimeoutWhileNavigating: TimeInterval = 30

    /// The top bar is always shown outside the Home and Clock tabs.
    private var showsChrome: Bool { !selectedTab.isAmbient || isChromeVisible }

    /// Ask for location (and fetch weather) only once a face that needs it is on
    /// screen, so the permission prompt appears in context rather than at first launch.
    private var needsLocation: Bool {
        selectedTab == .home || settings.faceType.usesLocation || detailFace?.usesLocation == true
    }

    var body: some View {
        ZStack(alignment: .top) {
            settings.theme.background.ignoresSafeArea()

            tabContent

            if selectedTab == .clock {
                // Keeps the top bar legible over bright faces.
                LinearGradient(colors: [settings.theme.background.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 260)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .opacity(showsChrome ? 1 : 0)
            }

            TopBarView(selectedTab: $selectedTab, isSettingsOpen: $isSettingsOpen)
                .opacity(showsChrome ? 1 : 0)
                .disabled(!showsChrome)

            if isSettingsOpen {
                SettingsPanelView()
                    .padding(.top, 104)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if isShowingSplash {
                LaunchSplashView { isShowingSplash = false }
                    .zIndex(10)
            }
        }
        .environment(settings)
        .environment(weather)
        .environment(schedule)
        .environment(reminders)
        .environment(\.chromeActivity, noteInteraction)
        .preferredColorScheme(settings.theme.colorScheme)
        .animation(.easeInOut(duration: 0.3), value: showsChrome)
        .animation(.easeInOut(duration: 0.3), value: isSettingsOpen)
        .animation(.easeInOut(duration: 0.3), value: settings.theme)
        .defaultFocus($isCanvasFocused, true)
        .onExitCommand(perform: exitAction)
        .onChange(of: selectedTab) {
            isSettingsOpen = false
            isChromeVisible = !(isZoomingBetweenHomeAndClock && selectedTab == .clock)
            if isZoomingBetweenHomeAndClock {
                isCanvasFocused = true
                isZoomingBetweenHomeAndClock = false
            }
            noteInteraction()
        }
        .onChange(of: isSettingsOpen) { noteInteraction() }
        .onChange(of: isCanvasFocused) { noteInteraction() }
        .onChange(of: scenePhase) {
            if scenePhase == .active { reminders.clearBadge() }
        }
        .onOpenURL(perform: handleDeepLink)
        .onAppear {
            // onAppear fires again whenever a full-screen cover closes; only set up once.
            guard !hasLaunched else { return }
            hasLaunched = true
            selectedTab = settings.launchTab
            // Act like a screensaver: don't let the TV dim or sleep while the app is open.
            UIApplication.shared.isIdleTimerDisabled = true
            reminders.clearBadge()
            publishTopShelf()
            #if DEBUG
            // Lets UI tests show the reminder alert without waiting for a real session.
            if UserDefaults.standard.bool(forKey: "UITestShowReminder") {
                activeReminder = Reminder(
                    id: "ui-test", seriesName: "Formula 1", eventName: "United States Grand Prix",
                    sessionName: "Race", start: .now.addingTimeInterval(14 * 60 + 30), weekendID: "2026-18"
                )
            }
            #endif
        }
        .onChange(of: reminders.reminders) { publishTopShelf() }
        .onChange(of: schedule.weekends) { publishTopShelf() }
        .onChange(of: settings.uses24HourTime) { publishTopShelf() }
        .task { await heartbeat() }
        .task(id: needsLocation) {
            if needsLocation { await refreshWeatherPeriodically() }
        }
        .task { await schedule.refresh() }
        .fullScreenCover(item: $detailFace) { face in
            FaceDetailView(face: face) {
                setAsClock(face)
            }
            .environment(settings)
            .environment(weather)
        }
        .fullScreenCover(item: $activeReminder) { reminder in
            ReminderTakeoverView(reminder: reminder) {
                activeReminder = nil
                noteInteraction()
            }
            .environment(settings)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            DashboardView(
                isChromeVisible: showsChrome,
                isCanvasFocused: $isCanvasFocused,
                acceptsInput: !isSettingsOpen,
                onInteraction: noteInteraction,
                onShowChrome: { isChromeVisible = true },
                onOpenClock: { zoom(to: .clock) },
                onCustomize: { detailFace = settings.faceType }
            )
            .transition(.scale(scale: 1.08).combined(with: .opacity))
        case .clock:
            ClockScreen(
                isChromeVisible: $isChromeVisible,
                isCanvasFocused: $isCanvasFocused,
                acceptsInput: !isSettingsOpen,
                onInteraction: noteInteraction,
                onCustomize: { detailFace = settings.faceType }
            )
            // Grows out of (and shrinks back into) the dashboard's clock tile.
            .transition(.scale(scale: 0.42, anchor: UnitPoint(x: 0.47, y: 0.4)).combined(with: .opacity))
        case .faces:
            FacesGalleryView { face in detailFace = face }
        case .sports:
            SportsView()
        case .world:
            WorldClockView()
        }
    }

    // MARK: - Behaviour

    private func noteInteraction() {
        lastInteraction = .now
    }

    private func hideChrome() {
        isChromeVisible = false
        isCanvasFocused = true
    }

    /// Animated switch between Home and the full-screen clock.
    private func zoom(to tab: AppTab) {
        isZoomingBetweenHomeAndClock = true
        withAnimation(.easeInOut(duration: 0.45)) {
            selectedTab = tab
        }
    }

    private func setAsClock(_ face: WatchFaceType) {
        settings.addToMyFaces(face)
        settings.faceType = face
        detailFace = nil
        selectedTab = .clock
    }

    /// Menu steps back one level at a time; at the top level it exits to the Home Screen.
    private var exitAction: (() -> Void)? {
        if isSettingsOpen {
            return { isSettingsOpen = false }
        }
        if selectedTab == .clock {
            return { zoom(to: .home) }
        }
        if selectedTab != .home {
            return { selectedTab = .home }
        }
        if isChromeVisible {
            return { hideChrome() }
        }
        return nil
    }

    private func publishTopShelf() {
        TopShelfPublisher.publish(
            reminders: reminders.reminders,
            nextWeekend: schedule.nextWeekend(after: .now),
            uses24Hour: settings.uses24HourTime
        )
    }

    private func heartbeat() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            let now = Date()

            let timeout = isCanvasFocused ? chromeTimeout : chromeTimeoutWhileNavigating
            if selectedTab.isAmbient, isChromeVisible, !isSettingsOpen, detailFace == nil,
               activeReminder == nil, now.timeIntervalSince(lastInteraction) > timeout {
                hideChrome()
            }

            if activeReminder == nil, let due = reminders.dueReminder(at: now) {
                reminders.markPresented(due)
                activeReminder = due
            }
        }
    }

    private func refreshWeatherPeriodically() async {
        while !Task.isCancelled {
            await weather.refreshIfNeeded()
            try? await Task.sleep(for: .seconds(10 * 60))
        }
    }

    /// `clockface://sports/f1/<weekend id>` opens that race weekend (used by Top Shelf).
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "clockface", url.host() == "sports" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        isSettingsOpen = false
        selectedTab = .sports
        if parts.first == "f1", parts.count > 1 {
            schedule.selectedWeekendID = parts[1]
        }
    }
}

#Preview {
    RootView()
}
