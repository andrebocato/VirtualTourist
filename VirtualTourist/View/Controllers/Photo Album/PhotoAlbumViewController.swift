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
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var barButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    var mapPin: MapPin!
    
    private var pages: Int?
    private var perPage: Int?
    
    var fetchedResultsController: NSFetchedResultsController<PersistedPhoto>?
    var dataController: DataController!
    
    // MARK: - IBActions
    
    @IBAction private func barButtonDidReceiveTouchUpInside(_ sender: Any) {
        deleteAllObjectsAndReloadRandomPage()
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultsController = NSFetchedResultsController<PersistedPhoto>()
        configureNSFetchedResultsController(with: mapPin!)
        loadViewData()
        loadMapData()
        
//        debugPrint("mapPin with id = \(mapPin.id!) passed successfully by dependency injection")
    }
    
    // MARK: - Functions
    
    private func loadMapData() {
        let coordinate = CLLocationCoordinate2D(latitude: mapPin.latitude, longitude: mapPin.longitude)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2500, longitudinalMeters: 2500)
        mapView.setMapCenterAndRegion(using: coordinate, region: region)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    private func loadViewData() {
        configureNSFetchedResultsController(with: mapPin)
        guard let pinPhotos = mapPin.photos, pinPhotos.count > 0 else {
            downloadAlbumForPin(mapPin, onCompletion: { [weak self] in
                self?.updateBarButton()
            })
            return
        }
    }
    
    private func deletePhoto(withID id: String,
                             at indexPath: IndexPath) {
        
        dataController.deletePersistedPhoto(withID: id, context: .view, onSuccess: { [weak self] in
            debugPrint("\(indexPath) deleted")
            
            self?.collectionView.reloadData()
            
        }, onFailure: { (persistenceError) in
            ErrorHelper.logPersistenceError(persistenceError)
        })
        
    }
    
    private func deleteAllObjectsAndReloadRandomPage() {
        guard let objectsToDelete = fetchedResultsController?.fetchedObjects, objectsToDelete.count > 0 else {
            self.downloadAlbumForPin(mapPin)
            return
        }
        
        dataController.deletePersistedPhotos(objectsToDelete, context: .view, onSuccess: { [weak self] in
            if let randomPage = self?.getRandomPage() {
                self?.downloadAlbumForPin(self!.mapPin, page: randomPage)
            } else {
                self?.downloadAlbumForPin(self!.mapPin)
            }
            
            }, onFailure: { (persistenceError) in
                ErrorHelper.logPersistenceError(persistenceError)
                AlertHelper.showAlert(inController: self, title: "Failed", message: "Failed to delete photos.", style: .default)
        })
    }
    
    private func downloadAlbumForPin(_ pin: MapPin,
                                     page: Int? = 1,
                                     onCompletion: (() -> Void)? = nil) {
        
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        FlickrService().searchAlbum(inCoordinate: coordinate, page: page ?? 1, onSuccess: { [weak self] (albumSearchResponse) in
            
            guard let flickrPhotos = albumSearchResponse?.photos?.photo else { return }
            
            self?.dataController.convertAndPersist(flickrPhotos, mapPin: pin, context: .view, onSuccess: { (persistedPhotoArray) in
//                debugPrint("successfully converted, persisted photos array (flickr -> persisted) and assigned to pin (id = \(pin.id ?? "")")
                
                persistedPhotoArray
                    .filter { $0.data == nil }
                    .forEach { self?.downloadBackupPhoto($0) }
                
            }, onFailure: { (persistenceError) in
                ErrorHelper.logPersistenceError(persistenceError)
                AlertHelper.showAlert(inController: self!, title: "No album", message: "Could not fetch an album for given pin location.", style: .default)
                
            })
            
            }, onFailure: { (error) in
                ErrorHelper.logServiceError(error as? ServiceError)
                AlertHelper.showAlert(inController: self, title: "Download failed", message: "Failed to download album for current pin coordinate.", style: .default)
                
        })
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
        
        guard let photoFromPinAlbum = fetchedResultsController?.object(at: indexPath) else { return }
        
        guard let imageData = photoFromPinAlbum.data else {
            if let url = photoFromPinAlbum.imageURL() {
                 downloadPhoto(from: url, for: cell, photoFromPinAlbum)
            }
            return
        }
        
        cell.configureWith(imageData)
//        debugPrint("cell \(indexPath) configured")
    }
    
    private func updateBarButton() {
        barButton.title = "New Collection"
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
                ErrorHelper.logPersistenceError(persistenceError)
                cell.configureWithNoImage()
            })
            
            }, onFailure: { (error) in
                AlertHelper.showAlert(inController: self, title: "Request failed", message: "The photo could not be downloaded.", style: .default)
                ErrorHelper.logServiceError(error as? ServiceError)
                cell.configureWithNoImage()
                
        })
    }
    
    private func downloadBackupPhoto(_ photo: PersistedPhoto) {
//        debugPrint("PersistedPhoto with id = \(photo.objectID) has no data. GETing it from Flickr...")
        guard let url = photo.imageURL() else { return }
        FlickrService().getPhotoData(fromURL: url, onSuccess: { [weak self] (imageData) in
            
            if let imageData = imageData {
                self?.dataController.updatePersistedPhotoData(withObjectID: photo.objectID, data: imageData, context: .background, onSuccess: {
//                    debugPrint("sucessfully assigned data to PersistedPhoto with id = (\(photo.objectID))")
                    
                }, onFailure: { (persistenceError) in
                    ErrorHelper.logPersistenceError(persistenceError)
                })
            }
            
            }, onFailure: { (error) in
                ErrorHelper.logServiceError(error as? ServiceError)
        })
    }
    
    
    private func getRandomPage() -> Int? {
        guard let pages = pages, let perPage = perPage else {
            return nil
        }
        return Int(arc4random_uniform(UInt32(min(pages,4000/perPage)))+1)
    }
    
}

// MARK: - Extensions

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source Methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let numberOfSections = fetchedResultsController?.sections?.count, numberOfSections > 0 else {
            collectionView.showEmptyView(message: "No sections.")
            return 0
        }
        return numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfItemsInSection = fetchedResultsController?.sections?[section].numberOfObjects ?? 0
        debugPrint("numberOfItemsInSection[\(section)] = \(numberOfItemsInSection)")
        return numberOfItemsInSection
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumViewCell", for: indexPath) as! AlbumViewCell
        
        configureCell(cell, at: indexPath)
        
        return cell
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate {
    
    // MARK: - UICollectioView Delegate Methods
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let photo = fetchedResultsController!.object(at: indexPath)
        return photo.data != nil
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = fetchedResultsController?.object(at: indexPath).id else { return }
        deletePhoto(withID: id, at: indexPath)
    }
    
}
