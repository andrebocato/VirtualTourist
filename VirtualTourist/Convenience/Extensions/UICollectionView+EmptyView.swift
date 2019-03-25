//
//  UICollectionView+EmptyView.swift
//  VirtualTourist
//
//  Created by André Sanches Bocato on 19/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func showEmptyView() {
        let noImagesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        noImagesLabel.text = "No images on that location."
        noImagesLabel.textColor = .gray
        noImagesLabel.numberOfLines = 1
        noImagesLabel.textAlignment = .center
//        noImagesLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        noImagesLabel.sizeToFit()
        
        DispatchQueue.main.async {
            self.backgroundView = noImagesLabel
        }
    }
    
    func hideEmptyView() {
        DispatchQueue.main.async {
            self.backgroundView = nil
        }
    }
    
}
