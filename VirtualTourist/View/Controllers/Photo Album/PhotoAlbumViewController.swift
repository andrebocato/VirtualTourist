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

class PhotoAlbumViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var albumCollectionView: UICollectionView! {
        didSet {
            albumCollectionView.delegate = self
            albumCollectionView.dataSource = self
        }
    }
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.isZoomEnabled = true
            mapView.isScrollEnabled = true
        }
    }
    
    // MARK: - Properties
    
    var receivedCoordinate = CLLocationCoordinate2D()
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Annotation>? {
        didSet {
            fetchedResultsController?.delegate = self
        }
    }
    // MARK: - IBActions
    
    @IBAction private func newCollectionBarButtonDidReceiveTouchUpInside(_ sender: Any) {
        //
    }
    
    // MARK: - Functions
    
    private func setUpFetchResultsController() {
        let fetchRequest: NSFetchRequest<Annotation> = Annotation.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "annotation")
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            ErrorHelper.persistenceError(.failedToFetchData)
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.setCenter(receivedCoordinate, animated: true)
    }
}

// MARK: - Extensions

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - UICollectioView Delegate Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumViewCell", for: indexPath) as? AlbumViewCell else { return UICollectionViewCell() }
        cell.configureCell()
        return cell
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    // MARK - MKMapView Delegate Methods
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    // MARK: - NSFetchedResultsController Delegate Methods
    
}
