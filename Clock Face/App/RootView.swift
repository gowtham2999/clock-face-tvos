import SwiftUI

struct RootView: View {
    @State private var settings = AppSettings()
    @State private var selectedTab: AppTab = .watch
    @State private var isSettingsOpen = false

    private let panelWidth: CGFloat = 560

    private var showsSettings: Bool { isSettingsOpen && selectedTab == .watch }

    var body: some View {
        ZStack(alignment: .topLeading) {
            settings.theme.background.ignoresSafeArea()

            tabContent
                .padding(.leading, showsSettings ? panelWidth : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 44) {
                TopBarView(selectedTab: $selectedTab, isSettingsOpen: $isSettingsOpen)

                if showsSettings {
                    SettingsPanelView()
                        // Full width so the panel's focus section sits under the palette
                        // button and a Down press from it lands in the panel.
                        .frame(width: panelWidth, alignment: .leading)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            DateCornerView()
        }
        .environment(settings)
        .preferredColorScheme(settings.theme.colorScheme)
        .animation(.easeInOut(duration: 0.3), value: showsSettings)
        .animation(.easeInOut(duration: 0.3), value: settings.theme)
        // Menu/back closes the panel; when it's closed, the default (exit app) applies.
        .onExitCommand(perform: showsSettings ? { isSettingsOpen = false } : nil)
        .onChange(of: selectedTab) {
            isSettingsOpen = false
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .watch:
            WatchFaceContainerView()
        case .focus:
            PlaceholderTabView(title: "Focus")
        case .worldTime:
            PlaceholderTabView(title: "World Time")
        }
    }
}

#Preview {
    RootView()
}
