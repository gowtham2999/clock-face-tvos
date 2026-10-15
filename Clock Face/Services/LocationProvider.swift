import CoreLocation

/// One-shot access to the device's approximate location, asking for
/// when-in-use permission the first time.
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pending: [CheckedContinuation<CLLocation?, Never>] = []

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentLocation() async -> CLLocation? {
        if let location = manager.location, location.timestamp.timeIntervalSinceNow > -3600 {
            return location
        }
        return await withCheckedContinuation { continuation in
            pending.append(continuation)
            guard pending.count == 1 else { return }
            manager.delegate = self
            requestForCurrentAuthorization()
        }
    }

    private func requestForCurrentAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            finish(with: nil)
        }
    }

    private func finish(with location: CLLocation?) {
        let continuations = pending
        pending.removeAll()
        continuations.forEach { $0.resume(returning: location) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard !self.pending.isEmpty, self.manager.authorizationStatus != .notDetermined else { return }
            self.requestForCurrentAuthorization()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in self.finish(with: location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(with: nil) }
    }
}
