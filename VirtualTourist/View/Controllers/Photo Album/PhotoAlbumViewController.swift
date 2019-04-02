//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//
// @TODO: properly implement collection view delegate and data source methods
// @TODO: implent mapview methods
// @TODO: if user taps a pin with no photo album, the api searches for an album on those coordinates. if no images are found, should present a "no images" label
// @TODO: present emptyview in case of no images

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
    
    var downloadedAlbum: FlickrPhotos?
    
    var mapPin: MapPin?
    var photo: PersistedPhoto?
    var photoID: String?
    
    var fetchedResultsController: NSFetchedResultsController<PersistedPhoto>? {
        didSet {
            fetchedResultsController?.delegate = self
        }
    }
    var dataController: DataController!

    // MARK: - IBActions
    
    @IBAction private func newCollectionBarButtonDidReceiveTouchUpInside(_ sender: Any) {
        // @TODO
        debugPrint("newCollectionBarButton tapped")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController = NSFetchedResultsController<PersistedPhoto>()
        
        fetchMapPin(onCompletion: {
            configureNSFetchedResultsController(with: mapPin!)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadMapData()
        
        if downloadedAlbum == nil {
            self.collectionView.showEmptyView()
        } else {
            self.collectionView.hideEmptyView()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        
        downloadAlbum()
    }
        
    private func fetchMapPin(onCompletion completed: () -> Void) {
        if let id = mapPin?.id {
            dataController.getMapPin(with: id, context: .view, onSuccess: { (responsePin) in
                guard let mapPin = responsePin else { return }
                debugPrint("sucessfully fetched MapPin with id = \(id)")
                self.mapPin = mapPin
                
            }, onFailure: { (error) in
                ErrorHelper.logPersistenceError(error!)
                AlertHelper.showAlert(inController: self, title: "No pin to load", message: "Could not fetch MapPin from local database.")
                
            }, onCompletion: nil)
        }
    }
    
    // MARK: - Networking Functions
    
    private func downloadAlbum() {
        guard let mapPin = mapPin else { return }
        let coordinate = CLLocationCoordinate2D(latitude: mapPin.latitude, longitude: mapPin.longitude)
        
        FlickrService().searchAlbum(inCoordinate: coordinate, page: 1, onSuccess: { [weak self] (albumSearchResponse) in
            guard let response = albumSearchResponse else { return }
            
            self?.downloadedAlbum = response.photos
            self?.collectionView.hideEmptyView()
            
            }, onFailure: { [weak self] (error) in
                self?.collectionView.hideEmptyView()
                AlertHelper.showAlert(inController: self!, title: "Request failed", message: "The album could not be downloaded.", rightAction: nil, onCompletion: nil)
                ErrorHelper.logServiceError(error as! ServiceError)
                
        }) { [weak self] in
            if self?.downloadedAlbum == nil {
                self?.collectionView.showEmptyView()
            } else {
                self?.collectionView.hideEmptyView()
            }
        }
    }
    
    // MARK: - Configuration
    
    private func configureNSFetchedResultsController(with mapPin: MapPin) {
//        let fetchRequest = NSFetchRequest<PersistedPhoto>(entityName: "PersistedPhoto")

        let fetchRequest: NSFetchRequest<PersistedPhoto> = PersistedPhoto.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mapPin == %@", mapPin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        
        do {
            try fetchedResultsController?.performFetch()
            
        } catch let error {
            debugPrint("fetchedResultsController error:\n\(error)")
            
            AlertHelper.showAlert(inController: self, title: "Error", message: "Could not find selected Map Pin on local database.", rightAction: UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                self.navigationController?.popViewController(animated: true)
            }))
        }
    }
    
    private func configureCell(_ cell: AlbumViewCell,
                               with photo: PersistedPhoto) {
       
        if let imageData = photo.data {
            cell.configureWith(imageData)
        } else {
            if let url = photo.imageURL() {
                FlickrService().getPhoto(fromURL: url, onSuccess: { [weak self] (data) in
                    guard let imageData = data else {
                        cell.noImage()
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.dataController.updatePersistedPhotoData(withObjectID: photo.objectID, data: imageData, context: .view, onSuccess: {
                            cell.configureWith(imageData)
                            
                        }, onFailure: { (persistenceError) in
                            ErrorHelper.logPersistenceError(persistenceError!)
                            cell.noImage()
                            
                        }, onCompletion: nil)
                    }
                    
                    }, onFailure: { (serviceError) in
                        AlertHelper.showAlert(inController: self, title: "Request failed", message: "The photo could not be downloaded.", rightAction: nil, onCompletion: nil)
                        ErrorHelper.logServiceError(serviceError as! ServiceError)
                        cell.noImage()
                        
                }, onCompletion: {
                    cell.stopLoading()
                })
            }
        }
    }
    
}

// MARK: - Extensions

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - UICollectioView Delegate Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let numberOfObjects = fetchedResultsController?.sections?[section].numberOfObjects,
            numberOfObjects > 0 else { return 0 }
        
        return numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumViewCell", for: indexPath) as! AlbumViewCell
        guard let photo = fetchedResultsController?.object(at: indexPath) else {
            return UICollectionViewCell()
        }
        
        configureCell(cell, with: photo)
        
        return cell
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
   
    // MARK: - MKMapViewDelegate Methods
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    // MARK: - NSFetchedResultsControllerDelegate Methods
 
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//    }

//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//    }
    
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
