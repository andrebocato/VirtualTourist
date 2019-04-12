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
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
        }
    }
    @IBOutlet private weak var imageView: UIImageView!
    
    // MARK; - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage()
        activityIndicator.startAnimating()
    }
    
    // MARK: - Configuration Functions
    
    func configureWith(_ imageData: Data) {
        imageView.isHidden = false
        imageView.image = UIImage(data: imageData)
        activityIndicator.stopAnimating()
    }
    
    func configureWithNoImage() {
        activityIndicator.stopAnimating()
    }

}
