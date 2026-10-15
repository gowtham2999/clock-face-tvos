import SwiftUI
import WeatherKit

/// App-wide settings, sliding in under the gear button. Per-face options
/// (like colour) live on each face's detail screen instead.
struct SettingsPanelView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WeatherStore.self) private var weather
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionLabel(text: "Appearance")
            PillSegmentedControl(options: AppTheme.allCases, selection: $settings.theme) { $0.displayName }
            PillSegmentedControl(options: [false, true], selection: $settings.uses24HourTime) {
                $0 ? "24-Hour" : "12-Hour"
            }

            SettingsSectionLabel(text: "Burn-in protection")
                .padding(.top, 20)
            PillSegmentedControl(options: [true, false], selection: $settings.pixelShiftEnabled) {
                $0 ? "Shift face" : "Off"
            }

            SettingsSectionLabel(text: "Sound")
                .padding(.top, 20)
            SoundSettingsSection(chimeSource: $settings.chimeSource, volume: $settings.volume)

            if let attribution = weather.attribution {
                // WeatherKit requires showing the Apple Weather mark and legal link wherever its data appears.
                VStack(alignment: .leading, spacing: 8) {
                    AsyncImage(url: colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Text(attribution.serviceName)
                    }
                    .frame(height: 20)
                    Text(attribution.legalPageURL.absoluteString)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.ink.opacity(0.45))
                }
                .padding(.top, 20)
            }
        }
        .padding(40)
        .frame(width: 560, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
        .focusSection()
    }
}
