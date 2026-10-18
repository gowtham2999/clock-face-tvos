import SwiftUI

/// Contract for a watch face view. `WatchFaceContainerView` hands every face the
/// current `Date`; faces read their styling (accent, theme, 12/24h) from the
/// `AppSettings` in the environment.
protocol WatchFace: View {
    init(date: Date)
}

extension EnvironmentValues {
    /// Replaces the theme background behind faces that paint one, so a face shown
    /// inside a dashboard tile blends with the tile instead of punching a hole in it.
    @Entry var faceBackground: Color?
}
