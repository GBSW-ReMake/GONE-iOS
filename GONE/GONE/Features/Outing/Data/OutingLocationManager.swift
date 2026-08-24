@preconcurrency import CoreLocation
import Foundation

@MainActor
final class OutingLocationManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    enum SharingState: Equatable {
        case idle
        case requestingPermission
        case sharing
        case denied
        case unavailable
    }

    @Published private(set) var state: SharingState = .idle
    @Published private(set) var latestCoordinate: OutingCoordinate?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var continuation: AsyncStream<OutingCoordinate>.Continuation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissionAndStartSharing() {
        guard CLLocationManager.locationServicesEnabled() else {
            state = .unavailable
            return
        }
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            state = .sharing
            manager.startUpdatingLocation()
        case .notDetermined:
            state = .requestingPermission
            manager.requestWhenInUseAuthorization()
        default:
            state = .denied
        }
    }

    func stopSharing() {
        manager.stopUpdatingLocation()
        continuation?.finish()
        continuation = nil
        state = .idle
    }

    func updates() -> AsyncStream<OutingCoordinate> {
        AsyncStream { continuation in
            self.continuation?.finish()
            self.continuation = continuation
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            state = .sharing
            manager.startUpdatingLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            state = .denied
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = OutingCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        latestCoordinate = coordinate
        continuation?.yield(coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        state = .unavailable
    }
}
