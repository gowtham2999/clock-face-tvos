import SwiftUI

struct SettingsPanelView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 22) {
            SettingsSectionLabel(text: "Face")
            PillSegmentedControl(options: WatchFaceType.allCases, selection: $settings.faceType) { $0.displayName }

            SettingsSectionLabel(text: "System Preferences")
                .padding(.top, 24)
            PillSegmentedControl(options: AppTheme.allCases, selection: $settings.theme) { $0.displayName }
            AccentColorSwatchRow(selection: $settings.accentColor)
            PillSegmentedControl(options: [false, true], selection: $settings.uses24HourTime) {
                $0 ? "24-Hour" : "12-Hour"
            }

            SettingsSectionLabel(text: "Sound")
                .padding(.top, 24)
            SoundSettingsSection(chimeSource: $settings.chimeSource, volume: $settings.volume)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .focusSection()
    }
}
