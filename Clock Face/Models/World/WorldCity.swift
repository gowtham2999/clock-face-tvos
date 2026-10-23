import Foundation

struct WorldCity: Identifiable, Hashable {
    /// The IANA time zone identifier, which also serves as the stable persisted ID.
    let id: String
    let name: String
    let country: String
    let region: Region
    let latitude: Double
    let longitude: Double

    enum Region: String, CaseIterable, Identifiable {
        case americas = "Americas"
        case europe = "Europe"
        case africaMiddleEast = "Africa & Middle East"
        case asia = "Asia"
        case oceania = "Oceania"

        var id: String { rawValue }
    }

    static let maximumSelection = 6

    static let defaultSelection = [
        "America/Los_Angeles", "America/New_York", "Europe/London",
        "Asia/Dubai", "Asia/Kolkata", "Asia/Tokyo",
    ]

    var timeZone: TimeZone { TimeZone(identifier: id) ?? .current }

    /// Daytime is 6 AM to 6 PM local time in the city.
    func isDaytime(at date: Date) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return (6..<18).contains(calendar.component(.hour, from: date))
    }

    static func city(withID id: String) -> WorldCity? {
        catalog.first { $0.id == id }
    }

    static let catalog: [WorldCity] = [
        WorldCity(id: "Pacific/Honolulu", name: "Honolulu", country: "United States", region: .americas, latitude: 21.31, longitude: -157.86),
        WorldCity(id: "America/Anchorage", name: "Anchorage", country: "United States", region: .americas, latitude: 61.22, longitude: -149.9),
        WorldCity(id: "America/Los_Angeles", name: "Los Angeles", country: "United States", region: .americas, latitude: 34.05, longitude: -118.24),
        WorldCity(id: "America/Vancouver", name: "Vancouver", country: "Canada", region: .americas, latitude: 49.28, longitude: -123.12),
        WorldCity(id: "America/Denver", name: "Denver", country: "United States", region: .americas, latitude: 39.74, longitude: -104.99),
        WorldCity(id: "America/Mexico_City", name: "Mexico City", country: "Mexico", region: .americas, latitude: 19.43, longitude: -99.13),
        WorldCity(id: "America/Chicago", name: "Chicago", country: "United States", region: .americas, latitude: 41.88, longitude: -87.63),
        WorldCity(id: "America/New_York", name: "New York", country: "United States", region: .americas, latitude: 40.71, longitude: -74.01),
        WorldCity(id: "America/Toronto", name: "Toronto", country: "Canada", region: .americas, latitude: 43.65, longitude: -79.38),
        WorldCity(id: "America/Bogota", name: "Bogotá", country: "Colombia", region: .americas, latitude: 4.71, longitude: -74.07),
        WorldCity(id: "America/Santiago", name: "Santiago", country: "Chile", region: .americas, latitude: -33.45, longitude: -70.67),
        WorldCity(id: "America/Sao_Paulo", name: "São Paulo", country: "Brazil", region: .americas, latitude: -23.55, longitude: -46.63),
        WorldCity(id: "America/Argentina/Buenos_Aires", name: "Buenos Aires", country: "Argentina", region: .americas, latitude: -34.6, longitude: -58.38),

        WorldCity(id: "Atlantic/Reykjavik", name: "Reykjavík", country: "Iceland", region: .europe, latitude: 64.15, longitude: -21.94),
        WorldCity(id: "Europe/Lisbon", name: "Lisbon", country: "Portugal", region: .europe, latitude: 38.72, longitude: -9.14),
        WorldCity(id: "Europe/London", name: "London", country: "United Kingdom", region: .europe, latitude: 51.51, longitude: -0.13),
        WorldCity(id: "Europe/Dublin", name: "Dublin", country: "Ireland", region: .europe, latitude: 53.35, longitude: -6.26),
        WorldCity(id: "Europe/Madrid", name: "Madrid", country: "Spain", region: .europe, latitude: 40.42, longitude: -3.7),
        WorldCity(id: "Europe/Paris", name: "Paris", country: "France", region: .europe, latitude: 48.86, longitude: 2.35),
        WorldCity(id: "Europe/Amsterdam", name: "Amsterdam", country: "Netherlands", region: .europe, latitude: 52.37, longitude: 4.9),
        WorldCity(id: "Europe/Berlin", name: "Berlin", country: "Germany", region: .europe, latitude: 52.52, longitude: 13.4),
        WorldCity(id: "Europe/Zurich", name: "Zurich", country: "Switzerland", region: .europe, latitude: 47.38, longitude: 8.54),
        WorldCity(id: "Europe/Rome", name: "Rome", country: "Italy", region: .europe, latitude: 41.9, longitude: 12.5),
        WorldCity(id: "Europe/Stockholm", name: "Stockholm", country: "Sweden", region: .europe, latitude: 59.33, longitude: 18.07),
        WorldCity(id: "Europe/Athens", name: "Athens", country: "Greece", region: .europe, latitude: 37.98, longitude: 23.73),
        WorldCity(id: "Europe/Istanbul", name: "Istanbul", country: "Türkiye", region: .europe, latitude: 41.01, longitude: 28.98),
        WorldCity(id: "Europe/Moscow", name: "Moscow", country: "Russia", region: .europe, latitude: 55.76, longitude: 37.62),

        WorldCity(id: "Africa/Casablanca", name: "Casablanca", country: "Morocco", region: .africaMiddleEast, latitude: 33.57, longitude: -7.59),
        WorldCity(id: "Africa/Lagos", name: "Lagos", country: "Nigeria", region: .africaMiddleEast, latitude: 6.52, longitude: 3.38),
        WorldCity(id: "Africa/Cairo", name: "Cairo", country: "Egypt", region: .africaMiddleEast, latitude: 30.04, longitude: 31.24),
        WorldCity(id: "Africa/Johannesburg", name: "Johannesburg", country: "South Africa", region: .africaMiddleEast, latitude: -26.2, longitude: 28.05),
        WorldCity(id: "Africa/Nairobi", name: "Nairobi", country: "Kenya", region: .africaMiddleEast, latitude: -1.29, longitude: 36.82),
        WorldCity(id: "Asia/Jerusalem", name: "Jerusalem", country: "Israel", region: .africaMiddleEast, latitude: 31.77, longitude: 35.21),
        WorldCity(id: "Asia/Riyadh", name: "Riyadh", country: "Saudi Arabia", region: .africaMiddleEast, latitude: 24.71, longitude: 46.68),
        WorldCity(id: "Asia/Qatar", name: "Doha", country: "Qatar", region: .africaMiddleEast, latitude: 25.29, longitude: 51.53),
        WorldCity(id: "Asia/Dubai", name: "Dubai", country: "United Arab Emirates", region: .africaMiddleEast, latitude: 25.2, longitude: 55.27),

        WorldCity(id: "Asia/Karachi", name: "Karachi", country: "Pakistan", region: .asia, latitude: 24.86, longitude: 67.0),
        WorldCity(id: "Asia/Kolkata", name: "Mumbai", country: "India", region: .asia, latitude: 19.08, longitude: 72.88),
        WorldCity(id: "Asia/Kathmandu", name: "Kathmandu", country: "Nepal", region: .asia, latitude: 27.72, longitude: 85.32),
        WorldCity(id: "Asia/Dhaka", name: "Dhaka", country: "Bangladesh", region: .asia, latitude: 23.81, longitude: 90.41),
        WorldCity(id: "Asia/Bangkok", name: "Bangkok", country: "Thailand", region: .asia, latitude: 13.76, longitude: 100.5),
        WorldCity(id: "Asia/Jakarta", name: "Jakarta", country: "Indonesia", region: .asia, latitude: -6.21, longitude: 106.85),
        WorldCity(id: "Asia/Singapore", name: "Singapore", country: "Singapore", region: .asia, latitude: 1.35, longitude: 103.82),
        WorldCity(id: "Asia/Kuala_Lumpur", name: "Kuala Lumpur", country: "Malaysia", region: .asia, latitude: 3.14, longitude: 101.69),
        WorldCity(id: "Asia/Hong_Kong", name: "Hong Kong", country: "China", region: .asia, latitude: 22.32, longitude: 114.17),
        WorldCity(id: "Asia/Shanghai", name: "Shanghai", country: "China", region: .asia, latitude: 31.23, longitude: 121.47),
        WorldCity(id: "Asia/Taipei", name: "Taipei", country: "Taiwan", region: .asia, latitude: 25.03, longitude: 121.57),
        WorldCity(id: "Asia/Manila", name: "Manila", country: "Philippines", region: .asia, latitude: 14.6, longitude: 120.98),
        WorldCity(id: "Asia/Seoul", name: "Seoul", country: "South Korea", region: .asia, latitude: 37.57, longitude: 126.98),
        WorldCity(id: "Asia/Tokyo", name: "Tokyo", country: "Japan", region: .asia, latitude: 35.68, longitude: 139.69),

        WorldCity(id: "Australia/Perth", name: "Perth", country: "Australia", region: .oceania, latitude: -31.95, longitude: 115.86),
        WorldCity(id: "Australia/Adelaide", name: "Adelaide", country: "Australia", region: .oceania, latitude: -34.93, longitude: 138.6),
        WorldCity(id: "Australia/Brisbane", name: "Brisbane", country: "Australia", region: .oceania, latitude: -27.47, longitude: 153.03),
        WorldCity(id: "Australia/Melbourne", name: "Melbourne", country: "Australia", region: .oceania, latitude: -37.81, longitude: 144.96),
        WorldCity(id: "Australia/Sydney", name: "Sydney", country: "Australia", region: .oceania, latitude: -33.87, longitude: 151.21),
        WorldCity(id: "Pacific/Auckland", name: "Auckland", country: "New Zealand", region: .oceania, latitude: -36.85, longitude: 174.76),
    ]
}
