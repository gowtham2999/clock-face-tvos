import SwiftUI

struct TopBarView: View {
    @Binding var selectedTab: AppTab
    @Binding var isSettingsOpen: Bool

    var body: some View {
        HStack(spacing: 20) {
            PillSegmentedControl(options: AppTab.allCases, selection: $selectedTab) { $0.displayName }

            // Only the Watch tab has settings in this version.
            PaletteButton(isSettingsOpen: $isSettingsOpen)
                .disabled(selectedTab != .watch)
        }
        .focusSection()
    }
}
