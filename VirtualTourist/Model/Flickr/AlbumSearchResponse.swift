//
//  AlbumSearchResponse.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 18/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

struct AlbumSearchResponse: Codable {
    
    var photos: FlickrPhotos?   
    var status: String?
    var code: Int?
    var message: String?
    
    enum CodingKeys: String, CodingKey {
        case photos, code, message
        case status = "stat"
    }
    
}
