//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.isZoomEnabled = true
            mapView.isScrollEnabled = true
        }
    }
    @IBOutlet private weak var longPressGestureRecognizer: UILongPressGestureRecognizer! {
        didSet {
            longPressGestureRecognizer.delegate = self
        }
    }

    // MARK: - Properties
    
    private var currentPin = MapPin()
    
    private var currentAnnotation: MKAnnotation? = nil
    private var annotations: [MKAnnotation]?
    
    var dataController: DataController!
    
    // MARK: - IBActions
    
    @IBAction private func longPressGestureRecognizerDidReceiveActionEvent(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            updatePinForLongPressGesture(sender)
            break
        case .ended:
            persistCurrentAnnotation()
            break
        default: return
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        loadMapData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let photoAlbumViewController = segue.destination as? PhotoAlbumViewController,
            segue.destination is PhotoAlbumViewController else { return }
        
        if segue.identifier == "AlbumSegue" {
            photoAlbumViewController.mapPin = currentPin
            
            photoAlbumViewController.dataController = dataController
        }
    }
    
    // MARK: - Functions
    
    private func loadMapData() {
        // @TODO: fetch map center
        // @TODO: fetch persisted annotations array
    }
    
    private func updatePinForLongPressGesture(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = longPressGestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        guard let currentAnnotation = currentAnnotation else {
            createAnnotation(with: newCoordinates)
            return
        }
        if (currentAnnotation.coordinate.latitude, currentAnnotation.coordinate.longitude) != (newCoordinates.latitude, newCoordinates.longitude) {
            createAnnotation(with: newCoordinates)
        }
    }
    
    private func createAnnotation(with coordinate: CLLocationCoordinate2D) {
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = coordinate
        currentAnnotation = newAnnotation
        mapView.addAnnotation(newAnnotation)
        annotations?.append(newAnnotation)
        // @TODO: persist annotation
    }
    
    private func persistCurrentAnnotation() {
        guard let coordinate = currentAnnotation?.coordinate else { return }
        
        dataController.addMapPin(at: coordinate, context: .view, onSuccess: { (pin) in
            debugPrint("successfully persisted \(pin)")
            
        }, onFailure: { (error) in
            AlertHelper.showAlert(inController: self, title: "Failed to save", message: "Could not save current annotation")
            ErrorHelper.logPersistenceError(error!)
            
        }, onCompletion: {
            self.currentAnnotation = nil
        })
        
    }
    
}

// MARK: - Extensions

extension TravelLocationsViewController: MKMapViewDelegate {
    
    // MARK: - MKMapView Delegate Methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        
        if let pin = pinView {
            pin.annotation = annotation
        } else {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView?.canShowCallout = true
            pinView?.pinTintColor = .red
        }
        
        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "AlbumSegue", sender: self)
    }
    
}

extension TravelLocationsViewController: UIGestureRecognizerDelegate {
    
    // MARK: - UIGestureRecognizer Delegate Methods
    
}
