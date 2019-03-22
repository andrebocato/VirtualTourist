//
//  FlickrPhotos.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 18/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

struct FlickrPhotos: Codable {
    
    var page: Int?
    var pages: Int?
    var perPage: Int?
    var total: String?
    var photo: [FlickrPhoto]?
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total, photo
        case perPage = "perpage"
    }
    
}
