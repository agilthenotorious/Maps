//
//  LocationViewController.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import CoreLocation
import MapKit
import UIKit

class LocationViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            self.mapView.showsUserLocation = true
            self.mapView.showsCompass = true
            self.mapView.delegate = self
        }
    }
    @IBOutlet private weak var searchBar: UISearchBar! {
        didSet {
            self.searchBar.delegate = self
        }
    }
    
    // MARK: Properties
    
    private var searchResults: [MKLocalSearchCompletion] = [] {
        didSet {
            updateMapWithCompletionResults()
        }
    }
    
    private var viewModel = LocationViewModel() {
        didSet {
            viewModel.delegate = self
        }
    }
    
    private lazy var locationHandler = LocationHandler(delegate: self)
    private var dataSource: [MKAnnotation] = []
    private var searchCompleter: MKLocalSearchCompleter?
    
    // MARK: Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.locationHandler.getUserLocation()
    }
    
    // MARK: Setup Search
    
    private func localSearch(with query: String) {
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = mapView.region
        
        viewModel.loadAnnotation(with: searchRequest) { annotations in
            guard let annotations = annotations,
                  !annotations.isEmpty else { return }
            self.updateViewWithDataSource(annotations: annotations)
            self.updateRegionForSearchRequest()
        }
    }
    
    // MARK: Setup View
    
    private func updateMapWithCompletionResults() {
        guard !searchResults.isEmpty else { return }
        viewModel.loadAnnotations(with: searchResults) { annotations in
            guard !annotations.isEmpty else { return }
            self.updateViewWithDataSource(annotations: annotations)
            self.updateRegionWithDataSource()
        }
    }
    
    private func updateViewWithDataSource(annotations: [CustomAnnotation]) {
        dataSource.removeAll()
        dataSource.append(contentsOf: annotations)
        
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        
        mapView.addAnnotations(dataSource)
    }
    
    private func updateRegionWithDataSource() {
        guard let region = viewModel.moveCameraToShow(annotations: dataSource) else { return }
        mapView.setRegion(region, animated: true)
    }
    
    private func updateRegionForSearchRequest() {
        guard !dataSource.isEmpty,
            let region = viewModel.moveCameraTo(annotation: dataSource[0]) else { return }
        mapView.setRegion(region, animated: true)
    }
}

// MARK: ViewModelProtocol
extension LocationViewController: ViewModelProtocol {
    
    func failed(with error: CustomError) {
        print(error)
    }
}

// MARK: MKMapViewDelegate

extension LocationViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? CustomAnnotation else { return nil }
        
        let view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotation")
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            dequeuedView.canShowCallout = true
            dequeuedView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
        }
        
        view.canShowCallout = true
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {}
}

// MARK: UISearchBarDelegate

extension LocationViewController: UISearchBarDelegate {
    
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
        self.localSearch(with: query)
    }
}

// MARK: LocationHandlerDelegate

extension LocationViewController: LocationHandlerDelegate {
    
    func received(location: CLLocation) {}
    
    func locationDidFail(withError error: Error) {
        print(error)
    }
}

// MARK: MKLocalSearchCompleterDelegate
extension LocationViewController: MKLocalSearchCompleterDelegate {
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error)
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
}

// MARK: UISearchResultsUpdating

extension LocationViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        searchCompleter?.queryFragment = searchController.searchBar.text ?? ""
    }
}
