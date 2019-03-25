//
//  PersistedPhoto+Extension.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 25/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

extension PersistedPhoto {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
    func imageURL(forSize size: FlickrPhotoSize = .thumbnail) -> String? {
        guard let server = server, let id = id, let secret = secret else {
            return nil
        }
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(size.rawValue).jpg"
    }
    
}
