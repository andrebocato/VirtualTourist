//
//  ErrorResponse.swift
//  VirtualTourist
//
//  Created by André Sanches Bocato on 19/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

struct ErrorResponse: Codable, Error {
    
    var code: Int?
    var message: String?
    
}
