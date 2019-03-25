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
    
    var receivedCoordinate: CLLocationCoordinate2D? = nil
    var downloadedAlbum: FlickrPhotos? = nil
    
    var dataController: DataController!

    // MARK: - IBActions
    
    @IBAction private func newCollectionBarButtonDidReceiveTouchUpInside(_ sender: Any) {
        //
    }
    
    // MARK: - Life Cycle
        
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
        
        clearMapData()
    }
    
    // MARK: - Functions
    
    private func loadMapData() {
        guard let coordinate = receivedCoordinate else { return }
        mapView.setCenter(coordinate, animated: true)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        downloadAlbum()
    }
    
    private func clearMapData() {
        receivedCoordinate = nil
    }
    
    // MARK: - Networking Functions
    
    private func downloadAlbum() {
        guard let coordinate = receivedCoordinate else { return }
        
        collectionView.showLoadingView()
        
        FlickrService().searchAlbum(inCoordinate: coordinate, page: 1, onSuccess: { [weak self] (albumSearchResponse) in
            guard let response = albumSearchResponse else {
                debugPrint("request failed. response came as nil")
                return
            }
            
            self?.downloadedAlbum = response.photos
            self?.collectionView.hideLoadingView()
            
            }, onFailure: { [weak self] (error) in
                self?.collectionView.hideLoadingView()
                AlertHelper.showAlert(inController: self!, title: "Request failed", message: "The album could not be downloaded.", rightAction: nil, onCompletion: nil)
                ErrorHelper.serviceError(error as! ServiceError)
                
        }) { [weak self] in
            debugPrint("request is over")
            if self?.downloadedAlbum == nil {
                self?.collectionView.showEmptyView()
            } else {
                self?.collectionView.hideEmptyView()
            }
        }
    }
    
    private func downloadPhoto() {
        //
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
    //
}
