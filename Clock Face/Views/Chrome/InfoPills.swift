import SwiftUI

/// Non-interactive glass capsule for ambient info in the top bar.
private struct InfoPill<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(Color.ink.opacity(0.9))
            .padding(.horizontal, 26)
            .frame(height: 64)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

struct DatePill: View {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return formatter
    }()

    var body: some View {
        TimelineView(.everyMinute) { context in
            InfoPill {
                Text(Self.formatter.string(from: context.date))
            }
        }
    }
}

/// Shows the current temperature; hidden entirely until weather is available.
struct WeatherPill: View {
    @Environment(WeatherStore.self) private var weather

    var body: some View {
        if let temperature = weather.formattedTemperature {
            InfoPill {
                HStack(spacing: 10) {
                    Text(temperature)
                    Image(systemName: weather.symbolName ?? "cloud")
                        .symbolRenderingMode(.multicolor)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weather \(temperature)")
        }
    }
}
