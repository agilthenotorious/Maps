//
//  LocationHandler.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import CoreLocation
import UIKit

protocol LocationHandlerDelegate: AnyObject, AlertHandlerProtocol {
    
    func received(location: CLLocation)
    func locationDidFail(withError error: Error)
}

class LocationHandler: NSObject {
    
    private lazy var locationManager: CLLocationManager = {
        let locationM = CLLocationManager()
        locationM.delegate = self
        locationM.desiredAccuracy = kCLLocationAccuracyBest
        locationM.pausesLocationUpdatesAutomatically = true
        locationM.distanceFilter = 5
        locationM.showsBackgroundLocationIndicator = true
        return locationM
    }()
    
    weak var delegate: LocationHandlerDelegate?
    
    init(delegate: LocationHandlerDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    func getUserLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            delegate?.showAlert(title: "Location Disabled", message: "Please enable your location services", buttons: [.cancel, .settings]) { _, type in
                switch type {
                case .cancel:
                    print("cancel pressed")
                    
                case .settings:
                    UIApplication.shared.openSettings()
                    
                default:
                    break
                }
            }
            return
        }
        checkAndPromptLocationAuthorization()
    }
    
    private func checkAndPromptLocationAuthorization() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            
        case .restricted, .denied:
            delegate?.showAlert(title: "Location Denied", message: "Please give access to your location.", buttons: [.cancel, .settings]) { _, type in
                switch type {
                case .settings:
                    UIApplication.shared.openSettings()
                    
                default:
                    break
                }
            }
            
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
            
        @unknown default:
            break
        }
    }
}

extension LocationHandler: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        delegate?.received(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationDidFail(withError: error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAndPromptLocationAuthorization()
    }
}
