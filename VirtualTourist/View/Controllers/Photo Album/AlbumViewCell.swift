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
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.isHidden = true
        }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.isHidden = false
        }
    }
    @IBOutlet weak var textLabel: UILabel! {
        didSet {
            textLabel.isHidden = true
        }
    }
    
    // MARK: - Functions
    
    func configureWith(_ imageData: Data) {
        imageView.image = UIImage(data: imageData)
    }
    
    func configureWithNoImage() {
        textLabel.text = "No image to display."
    }
    
    func startLoading() {
        imageView.isHidden = true

        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopLoading() {
        imageView.isHidden = false
        
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
}
