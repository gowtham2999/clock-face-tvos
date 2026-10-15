import SwiftUI

/// Searchable list of cities grouped by region; selecting toggles a city,
/// up to `WorldCity.maximumSelection`. Menu closes it.
struct CityPickerView: View {
    @Environment(AppSettings.self) private var settings
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(WorldCity.Region.allCases) { region in
                    let cities = matchingCities(in: region)
                    if !cities.isEmpty {
                        Section(region.rawValue) {
                            ForEach(cities) { city in
                                row(for: city)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "City or country")
            .navigationTitle("Cities — \(settings.worldCities.count) of \(WorldCity.maximumSelection)")
        }
    }

    private func row(for city: WorldCity) -> some View {
        let isSelected = settings.isWorldCitySelected(city)

        return Button {
            settings.toggleWorldCity(city)
        } label: {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                    Text(city.country)
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(TimeFormatting.string(.now, in: city.timeZone, uses24Hour: settings.uses24HourTime))
                    .foregroundStyle(.secondary)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.green : .secondary)
            }
        }
        .disabled(!isSelected && !settings.canAddWorldCity)
        .accessibilityLabel(city.name)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func matchingCities(in region: WorldCity.Region) -> [WorldCity] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        return WorldCity.catalog.filter { city in
            city.region == region && (trimmed.isEmpty
                || city.name.localizedCaseInsensitiveContains(trimmed)
                || city.country.localizedCaseInsensitiveContains(trimmed))
        }
    }
}
