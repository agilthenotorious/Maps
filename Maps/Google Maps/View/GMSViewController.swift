//
//  GMSViewController.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import GoogleMaps
import MapKit
import UIKit

class GMSViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet private weak var googleMapView: UIView!
    
    @IBOutlet private weak var searchBar: UISearchBar! {
        didSet {
            self.searchBar.delegate = self
        }
    }
    
    // MARK: Properties
    
    //swiftlint:disable implicitly_unwrapped_optional
    private var googleMap: GMSMapView! {
        didSet {
            googleMap.isMyLocationEnabled = true
            googleMap.settings.compassButton = true
            googleMap.settings.myLocationButton = true
            googleMap.delegate = self
        }
    }
    
    private var viewModel = GMSViewModel() {
        didSet {
            viewModel.delegate = self
        }
    }
    
    private lazy var locationHandler = LocationHandler(delegate: self)
    private var dataSource: [CustomGMSAnnotation] = []
    
    // MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    private func setupView() {
        googleMap = GMSMapView(frame: googleMapView.frame)
        view.addSubview(googleMap)
        locationHandler.getUserLocation()
    }
    
    private func loadPlacesInMap(with query: String) {
        viewModel.loadMarkers(with: query) { markers, error in
            if let markers = markers {
                self.googleMap.clear()
                self.dataSource.removeAll()
                self.dataSource.append(contentsOf: markers)
                for index in 0..<self.dataSource.count {
                    self.dataSource[index].map = self.googleMap
                }
                self.updateRegionWithDataSource()
            } else if let error = error {
                print(error)
            }
        }
    }
    
    private func updateRegionWithDataSource() {
        guard let update = viewModel.moveCameraToShow(markers: dataSource) else { return }
        googleMap.moveCamera(update)
    }
}

// MARK: GMSProtocol

extension GMSViewController: GMSProtocol {
    
    func failed(with error: CustomError) {
        var title = ""
        var message = String()
        
        switch error {
        case .emptyTextField:
            title = ""
            message = "Please enter a place"
            
        case .serverError, .decodingFailed:
            title = "Invalid"
            message = "Please enter a different place"
            
        case .noLocationFound:
            title = "Sorry"
            message = "Place could not be found"
        }
        showAlert(title: title, message: message) { _, _ in }
    }
}

// MARK: LocationHandlerDelegate

extension GMSViewController: LocationHandlerDelegate {
    
    func received(location: CLLocation) {
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 0)
        googleMap.camera = camera
    }
    
    func locationDidFail(withError error: Error) {
        print(error)
    }
}

// MARK: UISearchBarDelegate

extension GMSViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text?.trimmingCharacters(in: .whitespaces) else {
            locationDidFail(withError: CustomError.emptyTextField)
            return
        }
        searchBar.resignFirstResponder()
        loadPlacesInMap(with: query)
    }
}

// MARK: GMSMapViewDelegate

extension GMSViewController: GMSMapViewDelegate {}
