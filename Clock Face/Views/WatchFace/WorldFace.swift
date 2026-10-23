import SwiftUI

/// "World": a dot-matrix world map lit by the real sun (the night side dims),
/// with your cities glowing on it and their times alongside.
struct WorldFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let accent = settings.color(for: .world)?.primary ?? .orange
        let cities = Array(settings.worldCities.prefix(4))
        let subsolar = Self.subsolarPoint(at: date)

        GeometryReader { proxy in
            let size = proxy.size
            let unit = size.height
            let mapWidth = size.width * 0.6
            let spacing = mapWidth / CGFloat(WorldDotMap.columns)
            let mapHeight = spacing * CGFloat(WorldDotMap.rowCount)

            ZStack {
                faceBackground ?? .black

                Canvas { context, canvasSize in
                    drawMap(in: &context, spacing: spacing, subsolar: subsolar)
                    drawCities(settings.worldCities, in: &context, spacing: spacing, accent: accent)
                }
                .frame(width: mapWidth, height: mapHeight)
                .position(x: size.width * 0.05 + mapWidth / 2, y: size.height / 2)

                Grid(alignment: .leading, horizontalSpacing: unit * 0.05, verticalSpacing: unit * 0.045) {
                    ForEach(cities) { city in
                        GridRow {
                            Text(city.name)
                                .font(.system(size: unit * 0.032, weight: .regular))
                                .opacity(0.75)
                            Text(TimeFormatting.string(date, in: city.timeZone, uses24Hour: settings.uses24HourTime))
                                .font(.system(size: unit * 0.042, weight: .medium))
                                .monospacedDigit()
                        }
                    }
                }
                .lineLimit(1)
                .foregroundStyle(.white)
                .position(x: size.width * 0.82, y: size.height / 2)
            }
        }
    }

    private func drawMap(in context: inout GraphicsContext, spacing: CGFloat, subsolar: (latitude: Double, longitude: Double)) {
        let radius = spacing * 0.3
        let sunLatitude = subsolar.latitude * .pi / 180

        for dot in WorldDotMap.landDots {
            let coordinate = WorldDotMap.coordinate(row: dot.row, column: dot.column)
            let latitude = coordinate.latitude * .pi / 180
            let hourAngle = (coordinate.longitude - subsolar.longitude) * .pi / 180
            // Cosine of the sun's zenith angle: positive by day, negative by night.
            let sunHeight = sin(latitude) * sin(sunLatitude) + cos(latitude) * cos(sunLatitude) * cos(hourAngle)
            let daylight = min(max((sunHeight + 0.1) / 0.2, 0), 1)
            let opacity = 0.16 + 0.5 * daylight

            let center = CGPoint(x: (CGFloat(dot.column) + 0.5) * spacing, y: (CGFloat(dot.row) + 0.5) * spacing)
            context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                         with: .color(.white.opacity(opacity)))
        }
    }

    private func drawCities(_ cities: [WorldCity], in context: inout GraphicsContext, spacing: CGFloat, accent: Color) {
        for city in cities {
            let x = (city.longitude + 180) / 360 * Double(WorldDotMap.columns) * spacing
            let y = (WorldDotMap.northernmostLatitude + WorldDotMap.step / 2 - city.latitude) / WorldDotMap.step * spacing
            for (scale, opacity) in [(2.6, 0.18), (1.6, 0.35), (0.85, 1.0)] {
                let radius = spacing * scale * 0.5
                context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(accent.opacity(opacity)))
            }
        }
    }

    /// Where the sun is directly overhead: declination from the day of the year,
    /// longitude from UTC time with the equation of time.
    static func subsolarPoint(at date: Date) -> (latitude: Double, longitude: Double) {
        let days = date.timeIntervalSince1970 / 86_400 - 10_957.5 // days since J2000
        let meanAnomaly = (357.529 + 0.98560028 * days) * .pi / 180
        let meanLongitude = 280.459 + 0.98564736 * days
        let eclipticLongitude = (meanLongitude + 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly)) * .pi / 180
        let obliquity = 23.439 * .pi / 180
        let declination = asin(sin(obliquity) * sin(eclipticLongitude)) * 180 / .pi
        let rightAscension = atan2(cos(obliquity) * sin(eclipticLongitude), cos(eclipticLongitude)) * 180 / .pi
        // Equation of time in degrees (mean minus apparent solar longitude).
        var equationOfTime = (meanLongitude - rightAscension).truncatingRemainder(dividingBy: 360)
        if equationOfTime > 180 { equationOfTime -= 360 }
        if equationOfTime < -180 { equationOfTime += 360 }

        let utcHours = (date.timeIntervalSince1970 / 3600).truncatingRemainder(dividingBy: 24)
        var longitude = -15 * (utcHours - 12) - equationOfTime
        longitude = (longitude + 540).truncatingRemainder(dividingBy: 360) - 180
        return (declination, longitude)
    }
}

#Preview {
    WorldFace(date: .now)
        .environment(AppSettings())
}
