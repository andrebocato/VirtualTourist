//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//
// @TODO: if mapPin.photos = nil, downloads a flickr album and associates with mapPin
// @TODO: downloadAlbum() function should not be in the view controller

import UIKit
import MapKit
import CoreData
import CoreLocation

class PhotoAlbumViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    @IBOutlet private weak var newCollectionBarButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    var album: FlickrPhotos?
    var mapPin: MapPin?
    
    var fetchedResultsController: NSFetchedResultsController<PersistedPhoto>? {
        didSet {
            fetchedResultsController?.delegate = self
        }
    }
    var dataController: DataController!

    // MARK: - IBActions
    
    @IBAction private func newCollectionBarButtonDidReceiveTouchUpInside(_ sender: Any) {
        // @TODO: replace current ones with new set of images
        debugPrint("newCollectionBarButton tapped")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController = NSFetchedResultsController<PersistedPhoto>()
        
        guard mapPin != nil else {
            fetchMapPin(onCompletion: {
                configureNSFetchedResultsController(with: mapPin!)
            })
            return
        }
        
        debugPrint("mapPin with id = \(mapPin!.id!) passed successfully by dependency injection")
        
        configureNSFetchedResultsController(with: mapPin!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.reloadData()
        loadMapData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        album = nil
        mapPin = nil
        
    }
    
    // MARK: - Functions
    
    private func loadMapData() {
        guard let mapPin = mapPin else { return }
        let coordinate = CLLocationCoordinate2D(latitude: mapPin.latitude, longitude: mapPin.longitude)
        mapView.setCenter(coordinate, animated: true)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    // @TODO: fetch pin upon app lauching if nil
    private func fetchMapPin(onCompletion completed: () -> Void) {
        if let id = mapPin?.id {
            dataController.fetchMapPin(with: id, context: .view, onSuccess: { (responsePin) in
                guard let mapPin = responsePin else { return }
                debugPrint("sucessfully fetched MapPin with id = \(id)")
                self.mapPin = mapPin
                
            }, onFailure: { (error) in
                ErrorHelper.logPersistenceError(error!)
                AlertHelper.showAlert(inController: self, title: "No pin to load", message: "Could not fetch MapPin from local database.", style: .default)
                
            }, onCompletion: nil)
        }
    }
    
    private func deleteImage() {
        // @TODO: remove from the album, from collection view booth and from Core Data
    }
    
    // MARK: - Configuration
    
    private func configureNSFetchedResultsController(with mapPin: MapPin) {
        let fetchRequest: NSFetchRequest<PersistedPhoto> = PersistedPhoto.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mapPin == %@", mapPin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        
        do {
            try fetchedResultsController?.performFetch()
            
        } catch let error {
            debugPrint("fetchedResultsController error:\n\(error)")
            
            AlertHelper.showAlert(inController: self, title: "Error", message: "Could not find selected Map Pin on local database.", style: .default, rightAction: UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                self.navigationController?.popViewController(animated: true)
            }))
        }
    }
    
    private func configureCell(_ cell: AlbumViewCell,
                               at indexPath: IndexPath) {
        
        let index = indexPath.item
        guard let photoFromPinAlbum = mapPin?.photos?.allObjects[index] as? PersistedPhoto, let imageData = photoFromPinAlbum.data else { return }
        
        cell.configureWith(imageData)
        debugPrint("cell \(indexPath) configured")
    }
    
    // MARK: - Helper Functions
    
    private func downloadPhoto(from url: String,
                               for cell: AlbumViewCell,
                               _ photo: PersistedPhoto) {
        
        FlickrService().getPhotoData(fromURL: url, onSuccess: { [weak self] (data) in
            guard let imageData = data else {
                cell.configureWithNoImage()
                return
            }
            
            self?.dataController.updatePersistedPhotoData(withObjectID: photo.objectID, data: imageData, context: .view, onSuccess: {
                cell.configureWith(imageData)
                
            }, onFailure: { (persistenceError) in
                ErrorHelper.logPersistenceError(persistenceError!)
                cell.configureWithNoImage()
                
            }, onCompletion: nil)
            
            }, onFailure: { (serviceError) in
                AlertHelper.showAlert(inController: self, title: "Request failed", message: "The photo could not be downloaded.", style: .default, rightAction: nil, onCompletion: nil)
                ErrorHelper.logServiceError(serviceError as! ServiceError)
                cell.configureWithNoImage()
                
        }, onCompletion: nil)
    }
    
}

// MARK: - Extensions

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - UICollectioView Delegate Methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let numberOfSections = fetchedResultsController?.sections?.count, numberOfSections > 0 else {
            collectionView.showEmptyView(message: "No sections.")
            return 0
        }
        return numberOfSections
    }
    
    // MARK: - UICollectionView Data Source Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let numberOfObjects = fetchedResultsController?.sections?[section].numberOfObjects, numberOfObjects > 0 else {
            collectionView.showEmptyView(message: "No objects in section.")
            return 0
        }
        return numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumViewCell", for: indexPath) as! AlbumViewCell
        
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // @TODO: delete and replace photos
        debugPrint("cell item at \(indexPath) tapped")
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
   
    // MARK: - MKMapViewDelegate Methods
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    // MARK: - NSFetchedResultsControllerDelegate Methods
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView.reloadItems(at: [indexPath!])
            break
        default: return
        }
    }
    
}
