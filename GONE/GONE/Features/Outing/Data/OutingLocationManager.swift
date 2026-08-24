@preconcurrency import CoreLocation
import Combine
import Foundation
import UIKit

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
    @Published private(set) var isNearSchool = false

    private let manager = CLLocationManager()
    // TODO: 실제 학교 좌표를 서버 설정값으로 교체해야 합니다.
    private let schoolLocation = CLLocation(latitude: 35.1579, longitude: 128.9825)
    private let schoolArrivalRadius: CLLocationDistance = 150
    private var continuation: AsyncStream<OutingCoordinate>.Continuation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissionAndStartSharing() {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways:
            state = .sharing
            manager.allowsBackgroundLocationUpdates = hasLocationBackgroundMode
            manager.startUpdatingLocation()
        case .authorizedWhenInUse:
            state = .denied
        case .notDetermined:
            state = .requestingPermission
            manager.requestAlwaysAuthorization()
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
        if authorizationStatus == .authorizedAlways {
            state = .sharing
            manager.allowsBackgroundLocationUpdates = hasLocationBackgroundMode
            manager.startUpdatingLocation()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .denied || authorizationStatus == .restricted {
            state = .denied
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = OutingCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        latestCoordinate = coordinate
        isNearSchool = location.distance(from: schoolLocation) <= schoolArrivalRadius
        continuation?.yield(coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        state = .unavailable
    }

    private var hasLocationBackgroundMode: Bool {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        return modes.contains("location")
    }
}
