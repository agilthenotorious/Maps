//
//  LocationViewModel.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import MapKit

protocol ViewModelProtocol: AnyObject {
    func failed(with error: CustomError)
}

protocol LocationViewModelProtocol {
    var delegate: ViewModelProtocol? { get set }
}

class LocationViewModel: GeocoderHandler {
    
    // MARK: Delegates
    
    weak var delegate: ViewModelProtocol?
    
    // MARK: Fetch Data
    
    private func fetchData(with location: CLLocation, completion: @escaping ([CustomAnnotation]?, CustomError?) -> Void) {
        
        let link = "https://rapidapi.p.rapidapi.com/places?type=CITY&limit=100&skip=0&country=US%2CCA&q=New%20York"
        guard let url = URL(string: link) else { return }
        
        let headers = [
            "x-rapidapi-host": "spott.p.rapidapi.com",
            "x-rapidapi-key": "e9e886cd17msh32062c46cf93125p1a1b79jsn312df2c8284f"
        ]

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        ServiceManager.manager.request([Place].self, withRequest: request) { result in
            
            switch result {
            case .success(let cities):

                var annotations: [CustomAnnotation] = []
                cities.forEach {
                    annotations.append(CustomAnnotation(place: $0))
                }
                completion(annotations, nil)
                
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    // MARK: Setup Annotation
    
    func loadAnnotation(with searchRequest: MKLocalSearch.Request, completion: @escaping ([CustomAnnotation]?) -> Void) {
        
        var annotations: [CustomAnnotation] = []
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error").")
                completion(nil)
                return
            }

            for item in response.mapItems {
                annotations.append(CustomAnnotation(coordinate: item.placemark.coordinate, title: item.name ?? "", subtitle: ""))
            }
            completion(annotations)
        }
    }
    
    func loadAnnotations(with searchCompletionResults: [MKLocalSearchCompletion], completion: @escaping ([CustomAnnotation]) -> Void) {
        
        var annotations: [CustomAnnotation] = []
        
        for result in searchCompletionResults {
            geocoding(query: result.subtitle) { location, _ in
                if let location = location {
                    annotations.append(CustomAnnotation(coordinate: location.coordinate, title: result.title, subtitle: result.subtitle))
                }
            }
        }
        
        completion(annotations)
    }
    
    func loadAnnotations(with query: String, completion: @escaping ([CustomAnnotation]?, CustomError?) -> Void) {
        
        geocoding(query: query) { location, error in
            if let error = error {
                self.delegate?.failed(with: error)
            } else if let location = location {
                
                self.fetchData(with: location) { annotations, error in
                    if let error = error {
                        self.delegate?.failed(with: error)
                    } else if let annotations = annotations {
                        completion(annotations, nil)
                    }
                }
            }
        }
    }
    
    // MARK: Camera Setup
    
    func moveCameraTo(annotation: MKAnnotation) -> MKCoordinateRegion? {
        
        let delta = 5.0
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        return MKCoordinateRegion(center: annotation.coordinate, span: span)
    }

    func moveCameraToShow(annotations: [MKAnnotation]) -> MKCoordinateRegion? {
        
        guard !annotations.isEmpty, let location = annotations.first else { return nil }
        var minLongitude = location.coordinate.longitude
        var maxLongitude = location.coordinate.longitude
        var minLatitude = location.coordinate.latitude
        var maxLatitude = location.coordinate.latitude
        
        for annotations in annotations {
            if annotations.coordinate.longitude > maxLongitude {
                maxLongitude = annotations.coordinate.longitude
            } else if annotations.coordinate.longitude < minLongitude {
                minLongitude = annotations.coordinate.longitude
            }
            
            if annotations.coordinate.latitude > maxLatitude {
                maxLatitude = annotations.coordinate.latitude
            } else if annotations.coordinate.latitude < minLatitude {
                minLatitude = annotations.coordinate.latitude
            }
        }
        
        let zoom = 1.33
        var region = MKCoordinateRegion()
        region.center.latitude = (minLatitude + maxLatitude) / 2
        region.center.longitude = (minLongitude + maxLongitude) / 2
        region.span.latitudeDelta = abs(minLatitude - maxLatitude) * zoom
        region.span.longitudeDelta = abs(minLongitude - maxLongitude) * zoom
        return region
    }
}
