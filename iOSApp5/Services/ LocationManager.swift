import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let mgr = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?

    private override init() {
        super.init()
        mgr.delegate = self
    }

    func requestOneShot(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined: mgr.requestWhenInUseAuthorization()
        default: break
        }
        mgr.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.last)
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }
}
