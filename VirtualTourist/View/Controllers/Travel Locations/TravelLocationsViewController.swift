//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//
// @TODO: make zoom, drag, scroll and pinch possible
// @TODO: map center should be persistent. when app is launched.
// @TODO: tapping and holding map drops a new pin
// @TODO: when a pin is tapped, the app navigates to the photo album associated with the pin

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let photoAlbumViewController = segue.destination as? PhotoAlbumViewController, segue.destination is PhotoAlbumViewController else { return }
        
        
    }
    
}

// MARK: - Extensions

extension TravelLocationsViewController: MKMapViewDelegate {
    
    // MARK: - MKMapView Delegate Methods
    
}
