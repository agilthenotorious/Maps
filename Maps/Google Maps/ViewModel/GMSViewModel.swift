//
//  GMSViewModel.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import Foundation
import GoogleMaps
import MapKit

protocol GMSProtocol: AnyObject {
    func failed(with error: CustomError)
}

protocol GMSViewModelProtocol {
    var delegate: GMSProtocol? { get set }
}

class GMSViewModel: GeocoderHandler {
    
    // MARK: Delegates
    
    weak var delegate: GMSProtocol?
    
    // MARK: Fetch Data
    
    private func fetchData(with location: CLLocation, completion: @escaping ([CustomGMSAnnotation]?, CustomError?) -> Void) {
        
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

                var markers: [CustomGMSAnnotation] = []
                cities.forEach {
                    markers.append(CustomGMSAnnotation(place: $0))
                }
                completion(markers, nil)
                
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    // MARK: Camera
    
    func moveCameraToShow(markers: [CustomGMSAnnotation]) -> GMSCameraUpdate? {
        
        var bounds = GMSCoordinateBounds()
        for marker in markers {
            bounds = bounds.includingCoordinate(marker.coordinate)
        }
        return GMSCameraUpdate.fit(bounds)
    }
    
    // MARK: Markers
    
    func loadMarkers(with query: String, completion: @escaping ([CustomGMSAnnotation]?, CustomError?) -> Void) {
        
        geocoding(query: query) { location, error in
            if let error = error {
                self.delegate?.failed(with: error)
            } else if let location = location {
                
                self.fetchData(with: location) { markers, error in
                    if let error = error {
                        self.delegate?.failed(with: error)
                    } else if let markers = markers {
                        completion(markers, nil)
                    }
                }
            }
        }
    }
}
