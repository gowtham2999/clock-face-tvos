import Foundation

struct WorldCity: Identifiable, Hashable {
    /// The IANA time zone identifier, which also serves as the stable persisted ID.
    let id: String
    let name: String
    let country: String
    let region: Region

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
        WorldCity(id: "Pacific/Honolulu", name: "Honolulu", country: "United States", region: .americas),
        WorldCity(id: "America/Anchorage", name: "Anchorage", country: "United States", region: .americas),
        WorldCity(id: "America/Los_Angeles", name: "Los Angeles", country: "United States", region: .americas),
        WorldCity(id: "America/Vancouver", name: "Vancouver", country: "Canada", region: .americas),
        WorldCity(id: "America/Denver", name: "Denver", country: "United States", region: .americas),
        WorldCity(id: "America/Mexico_City", name: "Mexico City", country: "Mexico", region: .americas),
        WorldCity(id: "America/Chicago", name: "Chicago", country: "United States", region: .americas),
        WorldCity(id: "America/New_York", name: "New York", country: "United States", region: .americas),
        WorldCity(id: "America/Toronto", name: "Toronto", country: "Canada", region: .americas),
        WorldCity(id: "America/Bogota", name: "Bogotá", country: "Colombia", region: .americas),
        WorldCity(id: "America/Santiago", name: "Santiago", country: "Chile", region: .americas),
        WorldCity(id: "America/Sao_Paulo", name: "São Paulo", country: "Brazil", region: .americas),
        WorldCity(id: "America/Argentina/Buenos_Aires", name: "Buenos Aires", country: "Argentina", region: .americas),

        WorldCity(id: "Atlantic/Reykjavik", name: "Reykjavík", country: "Iceland", region: .europe),
        WorldCity(id: "Europe/Lisbon", name: "Lisbon", country: "Portugal", region: .europe),
        WorldCity(id: "Europe/London", name: "London", country: "United Kingdom", region: .europe),
        WorldCity(id: "Europe/Dublin", name: "Dublin", country: "Ireland", region: .europe),
        WorldCity(id: "Europe/Madrid", name: "Madrid", country: "Spain", region: .europe),
        WorldCity(id: "Europe/Paris", name: "Paris", country: "France", region: .europe),
        WorldCity(id: "Europe/Amsterdam", name: "Amsterdam", country: "Netherlands", region: .europe),
        WorldCity(id: "Europe/Berlin", name: "Berlin", country: "Germany", region: .europe),
        WorldCity(id: "Europe/Zurich", name: "Zurich", country: "Switzerland", region: .europe),
        WorldCity(id: "Europe/Rome", name: "Rome", country: "Italy", region: .europe),
        WorldCity(id: "Europe/Stockholm", name: "Stockholm", country: "Sweden", region: .europe),
        WorldCity(id: "Europe/Athens", name: "Athens", country: "Greece", region: .europe),
        WorldCity(id: "Europe/Istanbul", name: "Istanbul", country: "Türkiye", region: .europe),
        WorldCity(id: "Europe/Moscow", name: "Moscow", country: "Russia", region: .europe),

        WorldCity(id: "Africa/Casablanca", name: "Casablanca", country: "Morocco", region: .africaMiddleEast),
        WorldCity(id: "Africa/Lagos", name: "Lagos", country: "Nigeria", region: .africaMiddleEast),
        WorldCity(id: "Africa/Cairo", name: "Cairo", country: "Egypt", region: .africaMiddleEast),
        WorldCity(id: "Africa/Johannesburg", name: "Johannesburg", country: "South Africa", region: .africaMiddleEast),
        WorldCity(id: "Africa/Nairobi", name: "Nairobi", country: "Kenya", region: .africaMiddleEast),
        WorldCity(id: "Asia/Jerusalem", name: "Jerusalem", country: "Israel", region: .africaMiddleEast),
        WorldCity(id: "Asia/Riyadh", name: "Riyadh", country: "Saudi Arabia", region: .africaMiddleEast),
        WorldCity(id: "Asia/Qatar", name: "Doha", country: "Qatar", region: .africaMiddleEast),
        WorldCity(id: "Asia/Dubai", name: "Dubai", country: "United Arab Emirates", region: .africaMiddleEast),

        WorldCity(id: "Asia/Karachi", name: "Karachi", country: "Pakistan", region: .asia),
        WorldCity(id: "Asia/Kolkata", name: "Mumbai", country: "India", region: .asia),
        WorldCity(id: "Asia/Kathmandu", name: "Kathmandu", country: "Nepal", region: .asia),
        WorldCity(id: "Asia/Dhaka", name: "Dhaka", country: "Bangladesh", region: .asia),
        WorldCity(id: "Asia/Bangkok", name: "Bangkok", country: "Thailand", region: .asia),
        WorldCity(id: "Asia/Jakarta", name: "Jakarta", country: "Indonesia", region: .asia),
        WorldCity(id: "Asia/Singapore", name: "Singapore", country: "Singapore", region: .asia),
        WorldCity(id: "Asia/Kuala_Lumpur", name: "Kuala Lumpur", country: "Malaysia", region: .asia),
        WorldCity(id: "Asia/Hong_Kong", name: "Hong Kong", country: "China", region: .asia),
        WorldCity(id: "Asia/Shanghai", name: "Shanghai", country: "China", region: .asia),
        WorldCity(id: "Asia/Taipei", name: "Taipei", country: "Taiwan", region: .asia),
        WorldCity(id: "Asia/Manila", name: "Manila", country: "Philippines", region: .asia),
        WorldCity(id: "Asia/Seoul", name: "Seoul", country: "South Korea", region: .asia),
        WorldCity(id: "Asia/Tokyo", name: "Tokyo", country: "Japan", region: .asia),

        WorldCity(id: "Australia/Perth", name: "Perth", country: "Australia", region: .oceania),
        WorldCity(id: "Australia/Adelaide", name: "Adelaide", country: "Australia", region: .oceania),
        WorldCity(id: "Australia/Brisbane", name: "Brisbane", country: "Australia", region: .oceania),
        WorldCity(id: "Australia/Melbourne", name: "Melbourne", country: "Australia", region: .oceania),
        WorldCity(id: "Australia/Sydney", name: "Sydney", country: "Australia", region: .oceania),
        WorldCity(id: "Pacific/Auckland", name: "Auckland", country: "New Zealand", region: .oceania),
    ]
}
