import SwiftUI

struct TopBarView: View {
    @Binding var selectedTab: AppTab
    @Binding var isSettingsOpen: Bool

    var body: some View {
        HStack(spacing: 20) {
            PillSegmentedControl(options: AppTab.allCases, selection: $selectedTab) { $0.displayName }

            Spacer(minLength: 0)

            WeatherPill()
            DatePill()
            CircleIconButton(systemName: "gearshape.fill", accessibilityLabel: "Settings", isActive: isSettingsOpen) {
                isSettingsOpen.toggle()
            }
        }
        .focusSection()
    }
}
