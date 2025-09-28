import Foundation
import CoreLocation
import MapKit
import Combine

struct PlaceSearchResult {
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var nearbyPlaces: [String] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func searchNearbyPlaces(query: String, completion: @escaping ([String]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        // If we have location, search nearby. Otherwise search globally.
        if let location = currentLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 5000,  // 5km radius
                longitudinalMeters: 5000
            )
        }
        // If no location, MKLocalSearch will search globally

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                completion([])
                return
            }

            let placeNames = response.mapItems.map { $0.name ?? "Unknown Place" }
            DispatchQueue.main.async {
                completion(Array(placeNames.prefix(5))) // Limit to 5 results
            }
        }
    }

    func searchNearbyPlacesForMention(partialName: String, completion: @escaping ([String]) -> Void) {
        guard !partialName.isEmpty else {
            completion([])
            return
        }

        // Search for places that match the partial name
        searchNearbyPlaces(query: partialName) { places in
            let filteredPlaces = places.filter { place in
                place.lowercased().hasPrefix(partialName.lowercased())
            }
            completion(filteredPlaces)
        }
    }

    func searchPlacesWithCoordinates(query: String, completion: @escaping ([PlaceSearchResult]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        // If we have location, search nearby. Otherwise search globally.
        if let location = currentLocation {
            request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        }
        // If no location, MKLocalSearch will search globally

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                completion([])
                return
            }

            let results = response.mapItems.compactMap { item -> PlaceSearchResult? in
                guard let name = item.name else { return nil }

                // Build address from placemark components
                let placemark = item.placemark
                var addressComponents: [String] = []

                if let streetNumber = placemark.subThoroughfare {
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append("\(streetNumber) \(streetName)")
                    }
                } else if let streetName = placemark.thoroughfare {
                    addressComponents.append(streetName)
                }

                if let city = placemark.locality {
                    addressComponents.append(city)
                }

                if let state = placemark.administrativeArea {
                    addressComponents.append(state)
                }

                let address = addressComponents.isEmpty ? "Address not available" : addressComponents.joined(separator: ", ")

                return PlaceSearchResult(name: name, address: address, coordinate: placemark.coordinate)
            }

            DispatchQueue.main.async {
                completion(Array(results.prefix(10))) // Limit to 10 results
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
}