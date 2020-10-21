//
//  CustomGMSAnnotation.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import GoogleMaps

class CustomGMSAnnotation: GMSMarker {
    
    var coordinate: CLLocationCoordinate2D
    
    init(place: Place) {
        
        coordinate = place.coordinates.coordinates
        super.init()
        position = coordinate
        icon = nil
        title = place.name
        map = nil
    }
}
