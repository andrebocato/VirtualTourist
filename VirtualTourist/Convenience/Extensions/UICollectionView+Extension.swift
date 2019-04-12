//
//  UICollectionView+Extension.swift
//  VirtualTourist
//
//  Created by André Sanches Bocato on 19/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func showEmptyBackgroundView(message: String) {
        let noImagesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        noImagesLabel.text = message
        noImagesLabel.textColor = .gray
        noImagesLabel.numberOfLines = 1
        noImagesLabel.textAlignment = .center
        noImagesLabel.sizeToFit()
        
        DispatchQueue.main.async {
            self.backgroundView = noImagesLabel
        }
    }
    
    func hideBackgroudViews() {
        DispatchQueue.main.async {
            self.backgroundView = nil
        }
    }
    
    func showLoadingBackgroundView() {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.color = .black
        activityIndicator.sizeToFit()
        
        DispatchQueue.main.async {
            self.backgroundView = activityIndicator
        }
    }
    
}
