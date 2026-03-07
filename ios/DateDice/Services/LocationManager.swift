import Foundation
import CoreLocation

enum LocationError: Error {
    case denied
}

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var latitude: Double?
    var longitude: Double?
    var borough: String?
    var permissionDenied: Bool = false

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<(lat: Double, lng: Double, borough: String?), Error>?

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.delegate = self
    }

    func requestLocation() async throws -> (lat: Double, lng: Double, borough: String?) {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let status = manager.authorizationStatus
            switch status {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                permissionDenied = true
                continuation.resume(throwing: LocationError.denied)
                self.continuation = nil
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            @unknown default:
                manager.requestLocation()
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        // Truncate to 3 decimal places
        let lat = (location.coordinate.latitude * 1000).rounded() / 1000
        let lng = (location.coordinate.longitude * 1000).rounded() / 1000
        let detectedBorough = AppConstants.detectBorough(lat: lat, lng: lng)

        self.latitude = lat
        self.longitude = lng
        self.borough = detectedBorough

        continuation?.resume(returning: (lat: lat, lng: lng, borough: detectedBorough))
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionDenied = false
            // Only request location if we have a pending continuation
            if continuation != nil {
                manager.requestLocation()
            }
        case .denied, .restricted:
            permissionDenied = true
            continuation?.resume(throwing: LocationError.denied)
            continuation = nil
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
