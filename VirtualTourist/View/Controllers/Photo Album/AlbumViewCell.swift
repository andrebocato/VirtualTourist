//
//  AlbumViewCell.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//
// @TODO: implement configureCell() method

import UIKit

class AlbumViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.hidesWhenStopped = true
        }
    }
    
    // MARK: - Functions
    
    func configureWith(_ imageData: Data) {
        activityIndicator.stopAnimating()
        
        debugPrint("configuring cell with image data")
        imageView.image = UIImage(data: imageData)
    }
    
    func configureWithNoImage() {
        // @TODO: configure with "no image"
        activityIndicator.stopAnimating()
    }
    
    func startLoading() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopLoading() {
        activityIndicator.stopAnimating()
    }
    
}
