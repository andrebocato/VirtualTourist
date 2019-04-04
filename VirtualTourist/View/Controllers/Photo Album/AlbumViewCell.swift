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
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var noImageLabel: UILabel! {
        didSet {
            noImageLabel.text = "No image."
        }
    }
    
    // MARK: - Functions
    
    func configureWith(_ imageData: Data) {
        noImageLabel?.isHidden = true
        
        imageView.isHidden = false
        imageView.image = UIImage(data: imageData)
    }
    
    func configureWithNoImage() {
        noImageLabel.isHidden = false
    }

}
