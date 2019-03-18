//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//
// @TODO: properly implement collection view delegate and data source methods
// @TODO: implent mapview methods

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
    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    
    // MARK: - IBActions
    
    @IBAction private func newCollectionBarButtonItemDidReceiveTouchUpInside(_ sender: Any) {
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
    
    // MARK - MKMapView Delegate Methods
    
}
