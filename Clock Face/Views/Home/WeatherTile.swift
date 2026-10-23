import CoreLocation
import SwiftUI
import WeatherKit

/// Today's weather, read hour by hour from the saved forecast: the temperature and
/// conditions up top, then six details in a quiet two-column grid. Without a
/// forecast it shows the day's sun times instead, computed on device.
struct WeatherTile: View {
    let date: Date

    @Environment(WeatherStore.self) private var weather
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let now = weather.conditions(at: date)

        DashboardTile {
            VStack(alignment: .leading, spacing: 0) {
                header(hasForecast: now != nil)
                Spacer(minLength: 16)
                if let now {
                    hero(now)
                } else {
                    unavailable
                }
                Spacer(minLength: 16)
                Rectangle()
                    .fill(Color.ink.opacity(0.1))
                    .frame(height: 1)
                    .padding(.bottom, 28)
                MetricGrid(metrics: now.map { metrics(for: $0) } ?? sunMetrics)
            }
        }
        .accessibilityIdentifier("weatherTile")
    }

    // MARK: Header

    private func header(hasForecast: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(weather.placeName ?? "Weather")
                .font(.system(size: 30, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if weather.placeName != nil {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .opacity(0.5)
            }
            Spacer(minLength: 16)
            if hasForecast {
                attributionMark
            }
        }
    }

    // MARK: Hero

    private func hero(_ now: WeatherSnapshot.Hour) -> some View {
        let today = weather.today(at: date)

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(WeatherStore.format(Measurement(value: now.temperature, unit: .celsius)))
                    .font(.system(size: 132, weight: .light))
                    .tracking(-3)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.leading, -6)
                Text(now.condition)
                    .font(.system(size: 28, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let today {
                    Text("H \(WeatherStore.format(Measurement(value: today.high, unit: .celsius)))   L \(WeatherStore.format(Measurement(value: today.low, unit: .celsius)))")
                        .font(.system(size: 24))
                        .monospacedDigit()
                        .opacity(0.55)
                }
            }
            Spacer(minLength: 12)
            Image(systemName: now.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 76))
                .padding(.top, 24)
        }
        .animation(.easeInOut(duration: 0.6), value: now)
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 54))
                .symbolRenderingMode(.hierarchical)
                .opacity(0.5)
            Text("Weather unavailable")
                .font(.system(size: 30, weight: .medium))
            Text("Appears once this TV can use its location and the internet.")
                .font(.system(size: 21))
                .opacity(0.5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Metrics

    private func metrics(for now: WeatherSnapshot.Hour) -> [Metric] {
        let today = weather.today(at: date)
        let uv = today?.uvIndex ?? now.uvIndex
        let rain = today?.precipitationChance ?? now.precipitationChance
        let pressure = WeatherStore.formatPressure(hectopascals: now.pressure)
        let sun = sunTimes

        return [
            Metric(label: "Peak UV", symbol: "sun.max", value: "\(uv)", unit: UVLevel(index: uv).rawValue),
            Metric(label: "Rain", symbol: "umbrella", value: percent(rain), unit: "%"),
            Metric(label: "Humidity", symbol: "humidity", value: percent(now.humidity), unit: "%"),
            Metric(label: "Pressure", symbol: "gauge.with.dots.needle.50percent", value: pressure.value, unit: pressure.unit),
            timeMetric(label: "Sunrise", symbol: "sunrise", sun.sunrise),
            timeMetric(label: "Sunset", symbol: "sunset", sun.sunset),
        ]
    }

    /// Shown without a forecast: everything here is calculated on the TV.
    private var sunMetrics: [Metric] {
        let sun = sunTimes
        var daylight = Metric(label: "Daylight", symbol: "clock", value: "—")
        if let sunrise = sun.sunrise, let sunset = sun.sunset {
            let minutes = Int(sunset.timeIntervalSince(sunrise) / 60)
            daylight = Metric(label: "Daylight", symbol: "clock", value: "\(minutes / 60)h \(minutes % 60)m")
        }
        return [
            timeMetric(label: "Sunrise", symbol: "sunrise", sun.sunrise),
            timeMetric(label: "Sunset", symbol: "sunset", sun.sunset),
            timeMetric(label: "Solar Noon", symbol: "sun.max", sun.noon),
            daylight,
        ]
    }

    private var sunTimes: (sunrise: Date?, sunset: Date?, noon: Date?) {
        let coordinate = weather.location.map { GeoCoordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
            ?? .approximate(for: .current, at: date)
        let events = SolarCalculator.events(on: date, coordinate: coordinate, timeZone: .current)
        return (
            events.first { $0.event == .sunriseStarts }?.date,
            events.first { $0.event == .sunsetEnds }?.date,
            events.first { $0.event == .solarNoon }?.date
        )
    }

    private func timeMetric(label: String, symbol: String, _ moment: Date?) -> Metric {
        guard let moment else { return Metric(label: label, symbol: symbol, value: "—") }
        let parts = TimeFormatting.parts(moment, uses24Hour: settings.uses24HourTime)
        return Metric(label: label, symbol: symbol, value: parts.time, unit: parts.period)
    }

    private func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))"
    }

    // MARK: Attribution

    /// WeatherKit requires the Apple Weather mark wherever its data appears.
    @ViewBuilder
    private var attributionMark: some View {
        if let attribution = weather.attribution {
            AsyncImage(url: colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Text(attribution.serviceName)
            }
            .frame(height: 18)
            .opacity(0.5)
        } else {
            Text("\u{F8FF}Weather")
                .font(.system(size: 18, weight: .medium))
                .opacity(0.45)
        }
    }
}

// MARK: - Metric grid

private struct Metric: Identifiable {
    let label: String
    let symbol: String
    let value: String
    var unit: String?

    var id: String { label }
}

/// Two columns of small labelled values: a quiet caption with a monochrome
/// symbol, then the value with its unit set smaller beside it.
private struct MetricGrid: View {
    let metrics: [Metric]

    private let columns = [GridItem(.flexible(), spacing: 24, alignment: .leading), GridItem(.flexible(), spacing: 24, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 30) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 6) {
                    Label(metric.label.uppercased(), systemImage: metric.symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(1.2)
                        .opacity(0.5)
                        .lineLimit(1)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(metric.value)
                            .font(.system(size: 38, weight: .regular))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        if let unit = metric.unit {
                            Text(unit)
                                .font(.system(size: 21, weight: .medium))
                                .opacity(0.5)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("weatherMetric")
            }
        }
    }
}
