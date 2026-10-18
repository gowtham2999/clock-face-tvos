import SwiftUI

/// The World tab: up to six cities in a 3×2 grid.
struct WorldClockView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(WeatherStore.self) private var weather
    @State private var isPickingCities = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 32), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                SettingsSectionLabel(text: "\(settings.worldCities.count) of \(WorldCity.maximumSelection) cities")
                Spacer()
                Button {
                    isPickingCities = true
                } label: {
                    Label("Edit Cities", systemImage: "pencil")
                }
                .buttonStyle(ChipButtonStyle())
            }
            // Full-width section so pressing Down from any tab reaches Edit Cities.
            .focusSection()

            if settings.worldCities.isEmpty {
                PlaceholderTabView(title: "World", subtitle: "Choose Edit Cities to add up to six cities")
            } else {
                TimelineView(.everyMinute) { context in
                    LazyVGrid(columns: columns, spacing: 32) {
                        ForEach(settings.worldCities) { city in
                            CityCard(city: city, now: context.date, uses24Hour: settings.uses24HourTime)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 150)
        // Full screen rather than a sheet: tvOS sheets are narrow cards, which
        // cramp the search keyboard and city list.
        .fullScreenCover(isPresented: $isPickingCities) {
            CityPickerView()
                .environment(settings)
                .environment(weather)
                .background(settings.theme.background.ignoresSafeArea())
        }
    }
}

private struct CityCard: View {
    let city: WorldCity
    let now: Date
    let uses24Hour: Bool

    var body: some View {
        let time = TimeFormatting.parts(now, in: city.timeZone, uses24Hour: uses24Hour)
        let isDaytime = city.isDaytime(at: now)

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.system(size: 34, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(city.country)
                        .font(.system(size: 22))
                        .opacity(0.65)
                }
                Spacer(minLength: 12)
                Image(systemName: isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.multicolor)
            }

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(time.time)
                    .font(.system(size: 112, weight: .semibold).width(.compressed))
                    .monospacedDigit()
                if let period = time.period {
                    Text(period)
                        .font(.system(size: 30, weight: .semibold))
                }
            }

            Text("\(TimeFormatting.relativeDay(for: now, in: city.timeZone)) · \(TimeFormatting.offsetDescription(for: city.timeZone, at: now))")
                .font(.system(size: 22, weight: .medium))
                .opacity(0.7)
        }
        .foregroundStyle(.white)
        .padding(34)
        .frame(height: 340)
        .background(
            LinearGradient(
                colors: isDaytime
                    ? [Color(hex: 0x2B5B8A), Color(hex: 0x6FA3D0)]
                    : [Color(hex: 0x0B1020), Color(hex: 0x1F2A44)],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ),
            in: RoundedRectangle(cornerRadius: 36, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cityCard")
    }
}
