import SwiftUI

/// Renders any face for a given moment. Add new faces here as a `WatchFaceType` case.
struct FaceView: View {
    let face: WatchFaceType
    let date: Date

    var body: some View {
        switch face {
        case .analogClassic: AnalogClockFace(date: date)
        case .essential: EssentialFace(date: date)
        case .station: StationFace(date: date)
        case .sky: SkyFace(date: date)
        case .tint: TintFace(date: date)
        case .daylight: DaylightFace(date: date)
        case .flip: FlipClockFace(date: date)
        }
    }
}

/// A face that keeps itself up to date, ticking once per second.
struct LiveFaceView: View {
    let face: WatchFaceType

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            FaceView(face: face, date: context.date)
        }
    }
}
