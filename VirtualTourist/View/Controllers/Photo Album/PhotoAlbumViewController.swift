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
    
    var mapPin: MapPin!
    var downloadedAlbum: FlickrPhotos? = nil
    
    var fetchedResultsController: NSFetchedResultsController<PersistedPhoto>!
    var dataController: DataController!

    // MARK: - IBActions
    
    @IBAction private func newCollectionBarButtonDidReceiveTouchUpInside(_ sender: Any) {
        // @TODO
        debugPrint("newCollectionBarButton tapped")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNSFetchedResultsController(with: mapPin)
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
    
    // MARK: - Networking Functions
    
    private func downloadAlbum() {
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
        let fetchRequest = NSFetchRequest<PersistedPhoto>(entityName: "PersistedPhoto")

        fetchRequest.predicate = NSPredicate(format: "mapPin == %@", mapPin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch let error {
            debugPrint("fetchedResultsController error:\n\(error)")
            
            AlertHelper.showAlert(inController: self, title: "Error", message: "Could not find selected Map Pin on local database.", rightAction: UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                self.navigationController?.popViewController(animated: true)
            }))
        }
    }
    
}

// MARK: - Extensions

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - UICollectioView Delegate Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumViewCell", for: indexPath) as! AlbumViewCell
        
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
        
        return cell
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    //
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    //
}
