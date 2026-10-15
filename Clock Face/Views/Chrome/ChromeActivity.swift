import SwiftUI

extension EnvironmentValues {
    /// Called whenever the user moves focus around the chrome, so the Clock tab
    /// knows not to auto-hide the top bar while it's in use.
    @Entry var chromeActivity: () -> Void = {}
}
