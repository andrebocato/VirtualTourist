//
//  ErrorHelper.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 18/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

class ErrorHelper {
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Functions
    
    static func logServiceError(_ error: ServiceError) {
        debugPrint(error.localizedDescription + " Error code: \(error.code).")
    }
    
    static func logPersistenceError(_ error: PersistenceError) {
        debugPrint(error.localizedDescription + " Error code: \(error.code).")
    }
    
    static func logSerializationError(_ error: SerializationError) {
        debugPrint(error.localizedDescription + " Error code: \(error.code).")
    }
    
}
