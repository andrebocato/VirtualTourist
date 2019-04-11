//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import UIKit
import MapKit
import CoreData

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
    
    private var pinView: MKPinAnnotationView?
    
    private var currentAnnotation: MKAnnotation?
    private var annotations: [MKAnnotation]?
    
    var fetchedResultsController: NSFetchedResultsController<MapPin>? {
        didSet {
            fetchedResultsController?.delegate = self
        }
    }
    var dataController: DataController!
    
    // MARK: - IBActions
    
    @IBAction private func longPressGestureRecognizerDidReceiveActionEvent(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began: updatePinForLongPressGesture(sender)
        case .ended: persistCurrentAnnotation()
        default: return
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController = NSFetchedResultsController<MapPin>()
        configureNSFetchedResultsController()
        loadMapData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let photoAlbumViewController = segue.destination as? PhotoAlbumViewController,
            let pin = sender as? MapPin,
            segue.destination is PhotoAlbumViewController else { return }
        
        if segue.identifier == "AlbumSegue" {
            photoAlbumViewController.mapPin = pin
            photoAlbumViewController.dataController = self.dataController
        }
    }
    
    // MARK: - Functions
    
    private func loadMapData() {
        dataController.fetchAllPins(inContext: .view, onSuccess: { [weak self] (mapPinsArray) in
            guard let mapPins = mapPinsArray, let annotations = self?.convertMapPinsToAnnotations(mapPins), annotations.count > 0 else { return }
            
            DispatchQueue.main.async {
                self?.configureMapView(self!.mapView, with: annotations)
            }
            
            }, onFailure: { (persistenceError) in
                ErrorHelper.logPersistenceError(persistenceError)
                AlertHelper.showAlert(inController: self, title: "Failed", message: "Could not load map pins.", style: .default)
        })
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
    
    private func persistCurrentAnnotation() {
        guard let coordinate = currentAnnotation?.coordinate else { return }
        currentAnnotation = nil
        
        dataController.addMapPin(at: coordinate, context: .view, onSuccess: { [weak self] (pin) in
            debugPrint("successfully persisted \(pin)")
            
            self?.downloadAlbumForPin(pin)
            
            }, onFailure: { (persistenceError) in
                AlertHelper.showAlert(inController: self, title: "Failed to save", message: "Could not save current annotation", style: .default)
                ErrorHelper.logPersistenceError(persistenceError)
        })
    }
    
    private func downloadAlbumForPin(_ pin: MapPin) {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        FlickrService().searchAlbum(inCoordinate: coordinate, page: 1, onSuccess: { [weak self] (albumSearchResponse) in
            
            DispatchQueue.main.async { self?.view.isUserInteractionEnabled = false }
            
            guard let flickrPhotos = albumSearchResponse?.photos?.photo else { return }
            
            self?.dataController.convertAndPersist(flickrPhotos, mapPin: pin, context: .view, onSuccess: { (persistedPhotoArray) in
                debugPrint("successfully converted, persisted photos array (flickr -> persisted) and assigned to pin (id = \(pin.id ?? "")")
                
                for photo in persistedPhotoArray {
                    if photo.data == nil {
                        self?.downloadBackupPhoto(photo)
                    }
                }
                DispatchQueue.main.async { self?.view.isUserInteractionEnabled = true }
                
            }, onFailure: { (persistenceError) in
                AlertHelper.showAlert(inController: self!, title: "No album", message: "Could not fetch an album for given pin location.", style: .default)
                
            })
            
            }, onFailure: { (error) in
                AlertHelper.showAlert(inController: self, title: "Download failed", message: "Failed to download album for current pin coordinate.", style: .default)
                
        })
    }
    
    private func downloadBackupPhoto(_ photo: PersistedPhoto) {
        debugPrint("PersistedPhoto with id = \(photo.objectID) has no data. GETing it from Flickr...")
        guard let url = photo.imageURL() else { return }
        FlickrService().getPhotoData(fromURL: url, onSuccess: { [weak self] (imageData) in
            
            if let imageData = imageData {
                self?.dataController.updatePersistedPhotoData(withObjectID: photo.objectID, data: imageData, context: .background, onSuccess: {
                    debugPrint("sucessfully assigned data to PersistedPhoto with id = (\(photo.objectID))")
                    
                }, onFailure: { (persistenceError) in
                    ErrorHelper.logPersistenceError(persistenceError)
                })
            }
            
            }, onFailure: { (error) in
                ErrorHelper.logServiceError(error as? ServiceError)
        })
    }
    
    // MARK: - Configuration
    
    private func configureNSFetchedResultsController() {
        let fetchRequest: NSFetchRequest<MapPin> = MapPin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "mapPin")
        
        do {
            try fetchedResultsController?.performFetch()
            
        } catch let error {
            debugPrint("fetchedResultsController error:\n\(error)")
            
            AlertHelper.showAlert(inController: self, title: "Error", message: "Could not find selected Map Pin on local database.", style: .default, rightAction: UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                self.navigationController?.popViewController(animated: true)
            }))
        }
    }
    
    private func configureMapView(_ mapView: MKMapView,
                                  with annotations: [MKAnnotation]) {
        
        mapView.addAnnotations(annotations)
        guard let coordinate = annotations.last?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000000, longitudinalMeters: 10000000)
        mapView.setMapCenterAndRegion(using: coordinate, region: region)
    }
    
    // MARK: - Helper Functions
    
    private func createAnnotation(with coordinate: CLLocationCoordinate2D) {
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = coordinate
        currentAnnotation = newAnnotation
        mapView.addAnnotation(newAnnotation)
        annotations?.append(newAnnotation)
    }
    
    private func convertMapPinsToAnnotations(_ mapPins: [MapPin]) -> [MKAnnotation]? {
        var convertedAnnotations = [MKAnnotation]()
        
        for mapPin in mapPins {
            let coordinate = CLLocationCoordinate2D(latitude: mapPin.latitude, longitude: mapPin.longitude)
            let convertedAnnotation = MKPointAnnotation()
            convertedAnnotation.coordinate = coordinate
            convertedAnnotations.append(convertedAnnotation)
        }
        
        return convertedAnnotations
    }
}

// MARK: - Extensions

extension TravelLocationsViewController: MKMapViewDelegate {
    
    // MARK: - MKMapView Delegate Methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        
        if let pin = pinView {
            pin.annotation = annotation
        } else {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView?.canShowCallout = true
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        guard let selectedAnnotationCordinate = view.annotation?.coordinate else { return }
        let pinIDForSelectedAnnotation = dataController.getIdForPinAtCoordinate(at: selectedAnnotationCordinate)
        
        dataController.fetchMapPin(with: pinIDForSelectedAnnotation, onSuccess: { [weak self] (mapPin) in
            guard let mapPin = mapPin else { return }
            self?.performSegue(withIdentifier: "AlbumSegue", sender: mapPin)
            
            }, onFailure: { [weak self] persistenceError in
                ErrorHelper.logPersistenceError(persistenceError)
                AlertHelper.showAlert(inController: self, title: "ERROR!", message: "Could not fetch pin.", style: .default)
        })
    }
    
}

extension TravelLocationsViewController: UIGestureRecognizerDelegate {
}

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
}
