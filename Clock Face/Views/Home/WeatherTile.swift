import CoreLocation
import SwiftUI
import WeatherKit

/// Current conditions, the next six hours and the next five days. Without
/// WeatherKit data it shows the day's sun times instead, computed on device.
struct WeatherTile: View {
    let date: Date

    @Environment(WeatherStore.self) private var weather
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        DashboardTile {
            VStack(alignment: .leading, spacing: 0) {
                header
                if weather.hasForecast {
                    forecast
                } else {
                    sunTimes
                }
            }
        }
        .accessibilityIdentifier("weatherTile")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            if let place = weather.placeName {
                Label {
                    Text(place)
                } icon: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 22))
                }
                .labelStyle(TrailingIconLabelStyle())
                .font(.system(size: 32, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            } else {
                Text("Today")
                    .font(.system(size: 32, weight: .semibold))
            }
            Spacer(minLength: 16)
            attributionMark
        }
    }

    // MARK: Forecast

    @ViewBuilder
    private var forecast: some View {
        HStack(alignment: .center) {
            Text(weather.formattedTemperature ?? "")
                .font(.system(size: 120, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: weather.symbolName ?? "cloud")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 60))
                if let condition = weather.conditionDescription {
                    Text(condition)
                        .font(.system(size: 26, weight: .medium))
                        .lineLimit(1)
                }
                if let high = weather.todayHigh, let low = weather.todayLow {
                    Text("H:\(WeatherStore.format(high))  L:\(WeatherStore.format(low))")
                        .font(.system(size: 24))
                        .opacity(0.7)
                }
            }
        }
        .padding(.top, 4)

        divider

        HStack(spacing: 0) {
            ForEach(Array(weather.hourly.enumerated()), id: \.element.id) { index, hour in
                VStack(spacing: 10) {
                    Text(index == 0 ? "Now" : hourLabel(hour.date))
                        .font(.system(size: 21, weight: .semibold))
                        .opacity(0.7)
                    Image(systemName: hour.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 28))
                        .frame(height: 34)
                    Text(WeatherStore.format(hour.temperature))
                        .font(.system(size: 24, weight: .medium))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
        }

        divider

        VStack(spacing: 6) {
            ForEach(weather.daily) { day in
                HStack {
                    Text(day.date.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 25))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .layoutPriority(1)
                    Spacer(minLength: 8)
                    Image(systemName: day.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 26))
                        .frame(width: 60)
                    Text(WeatherStore.format(day.high))
                        .font(.system(size: 25, weight: .medium))
                        .frame(width: 70, alignment: .trailing)
                    Text(WeatherStore.format(day.low))
                        .font(.system(size: 25))
                        .opacity(0.5)
                        .frame(width: 70, alignment: .trailing)
                }
                .monospacedDigit()
                .frame(height: 40)
            }
        }
        Spacer(minLength: 0)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.ink.opacity(0.1))
            .frame(height: 1)
            .padding(.vertical, 22)
    }

    private func hourLabel(_ date: Date) -> String {
        if settings.uses24HourTime {
            return date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)))
        }
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
    }

    // MARK: Sun times (fallback)

    @ViewBuilder
    private var sunTimes: some View {
        let coordinate = weather.location.map { GeoCoordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
            ?? .approximate(for: .current, at: date)
        let events = SolarCalculator.events(on: date, coordinate: coordinate, timeZone: .current)
        let sunrise = events.first { $0.event == .sunriseStarts }?.date
        let sunset = events.first { $0.event == .sunsetEnds }?.date
        let noon = events.first { $0.event == .solarNoon }?.date

        Spacer(minLength: 0)
        VStack(alignment: .leading, spacing: 30) {
            sunRow("sunrise.fill", title: "Sunrise", value: sunrise)
            sunRow("sun.max.fill", title: "Solar noon", value: noon)
            sunRow("sunset.fill", title: "Sunset", value: sunset)
            if let sunrise, let sunset {
                let length = sunset.timeIntervalSince(sunrise)
                HStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 34))
                        .frame(width: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daylight")
                            .font(.system(size: 22, weight: .semibold))
                            .opacity(0.6)
                        Text("\(Int(length / 3600))h \(Int(length.truncatingRemainder(dividingBy: 3600) / 60))m")
                            .font(.system(size: 40, weight: .medium))
                    }
                }
            }
        }
        Spacer(minLength: 0)
        Text("Weather appears once location and internet are available.")
            .font(.system(size: 20))
            .opacity(0.45)
    }

    private func sunRow(_ symbol: String, title: String, value: Date?) -> some View {
        HStack(spacing: 20) {
            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 34))
                .frame(width: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .opacity(0.6)
                Text(value.map { TimeFormatting.string($0, uses24Hour: settings.uses24HourTime) } ?? "—")
                    .font(.system(size: 40, weight: .medium))
                    .monospacedDigit()
            }
        }
    }

    // MARK: Attribution

    /// WeatherKit requires the Apple Weather mark wherever its data appears.
    @ViewBuilder
    private var attributionMark: some View {
        if weather.hasForecast {
            if let attribution = weather.attribution {
                AsyncImage(url: colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Text(attribution.serviceName)
                }
                .frame(height: 18)
                .opacity(0.6)
            } else {
                Text("\u{F8FF}Weather")
                    .font(.system(size: 18, weight: .medium))
                    .opacity(0.5)
            }
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            configuration.title
            configuration.icon
        }
    }
}
