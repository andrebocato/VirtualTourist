//
//  MKMapView+Extension.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 09/04/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

extension MKMapView {
    
    // MARK: - Functions
    
    func setMapCenterAndRegion(using coordinate: CLLocationCoordinate2D,
                               region: MKCoordinateRegion) {
        
        self.setCenter(coordinate, animated: true)
        self.setRegion(region, animated: true)
    }
    
}
