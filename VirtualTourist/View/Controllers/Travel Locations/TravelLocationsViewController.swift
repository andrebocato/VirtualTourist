//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//
// @TODO: when the user drops the pin on the map, start downloading the images immediately without waiting for the user to navigate to the collection view.

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController {

    // MARK: - IBOutlets
    
    var downloadedData = [Data]() // gambs pra ver duplicacao
    
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
        // @TODO: fetch map center
        // @TODO: fetch zoom level
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
        currentAnnotation = nil
        
        dataController.addMapPin(at: coordinate, context: .view, onSuccess: { [weak self] (pin) in
            debugPrint("successfully persisted \(pin)")
            
            self?.downloadAlbumForPin(pin)
            
        }, onFailure: { (error) in
            AlertHelper.showAlert(inController: self, title: "Failed to save", message: "Could not save current annotation", style: .default)
            ErrorHelper.logPersistenceError(error!)
            
        })
    }
    
    private func downloadAlbumForPin(_ pin: MapPin) {
        
        // @TODO: startLoading()
        pinView?.isUserInteractionEnabled = false
        
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        FlickrService().searchAlbum(inCoordinate: coordinate, page: 1, onSuccess: { [weak self] (albumSearchResponse) in // @TODO: change page number to random page from album response's pages
            guard let flickrPhotos = albumSearchResponse?.photos?.photo else { return }
            
            self?.dataController.convertAndPersist(flickrPhotos, mapPin: pin, context: .view, onSuccess: { (persistedPhotoArray) in
                debugPrint("successfully converted, persisted photos array (flickr -> persisted) and assigned to pin (id = \(pin.id ?? "")")
                
                for photo in persistedPhotoArray {
                    if photo.data == nil {
                        self?.downloadBackupPhoto(photo)
                    }
                }
                
            }, onFailure: { (error) in
                ErrorHelper.logPersistenceError(error!)
                AlertHelper.showAlert(inController: self!, title: "No album", message: "Could not fetch an album for given pin location.", style: .default)
                
            }, onCompletion: nil)
            
        }, onFailure: { (error) in
            ErrorHelper.logServiceError(error as! ServiceError)
            AlertHelper.showAlert(inController: self, title: "Download failed", message: "Failed to download album for current pin coordinate.", style: .default)
            
        }, onCompletion: {
            // @TODO: stopLoading()
            self.pinView!.isUserInteractionEnabled = true
        })
    }
    
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
    
    private func downloadBackupPhoto(_ photo: PersistedPhoto) {
        debugPrint("PersistedPhoto with id = \(photo.objectID) has no data. GETing it from Flickr...")
        guard let url = photo.imageURL() else { return }
        FlickrService().getPhotoData(fromURL: url, onSuccess: { [weak self] (imageData) in
            // @TODO: create [Data]?
            if let imageData = imageData {
                
                
                if self?.downloadedData.contains(imageData) == false {
                     self?.downloadedData.append(imageData)
                } else {
                    debugPrint("Duplicated")
                }
                
                self?.dataController.updatePersistedPhotoData(withObjectID: photo.objectID, data: imageData, context: .background, onSuccess: {
                    debugPrint("sucessfully assigned data to PersistedPhoto with id = (\(photo.objectID))")
                    
                }, onFailure: { (persistenceError) in
                    ErrorHelper.logPersistenceError(persistenceError!)
                    
                }, onCompletion: nil)
            }
            
            }, onFailure: { (error) in
                ErrorHelper.logServiceError(error as! ServiceError)
                
        }, onCompletion: nil)
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
        }, onFailure: { [weak self] error in
            AlertHelper.showAlert(inController: self, title: "ERROR!", message: "Could not fetch pin.", style: .default)
        })
    }
    
}

extension TravelLocationsViewController: UIGestureRecognizerDelegate {
    
    // MARK: - UIGestureRecognizer Delegate Methods
    
}

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {

    // MARK: - NSFetchedResultsControllerDelegate Methods

}
