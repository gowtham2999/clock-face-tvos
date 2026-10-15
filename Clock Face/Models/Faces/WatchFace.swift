import SwiftUI

/// Contract for a watch face view. `WatchFaceContainerView` hands every face the
/// current `Date`; faces read their styling (accent, theme, 12/24h) from the
/// `AppSettings` in the environment.
protocol WatchFace: View {
    init(date: Date)
}
