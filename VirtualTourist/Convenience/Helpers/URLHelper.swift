//
//  URLHelper.swift
//  VirtualTourist
//
//  Created by André Sanches Bocato on 19/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

class URLHelper {
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Functions
    
    static func escapedParameters(from parameters: [String: Any]) -> String {
        guard !parameters.isEmpty else { return "" }
        
        var keyValuePairs = [String]()
        for (key, value) in parameters {
            // make sure that it is a string value
            let stringValue = "\(value)"
            // escape it
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            // append it
            keyValuePairs.append(key + "=" + "\(escapedValue!)")
        }
        
        return "?\(keyValuePairs.joined(separator: "&"))"
    }
    
}
