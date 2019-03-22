//
//  Service.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 18/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

class Service {
    
    // MARK: - Shared Instance
    
    static let shared = Service()
    
    // MARK: - Enums
    
    enum HTTPMethod: String {
        case get = "GET"
    }
    
    // MARK: - Properties
    
    var defaultHeaders: [String: String] = [
        "content-type": "application/json",
        "accept": "application/json"
    ]
    
    // MARK: - Functions
    
    func request(httpMethod: HTTPMethod,
                 url: URL,
                 parameters: [String: Any]? = nil,
                 headers: [String: String]? = nil) -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.allHTTPHeaderFields = defaultHeaders
        
        if let parameters = parameters {
            request.httpBody = JSON.serialize(dictionary: parameters)
        }
        
        guard let headers = headers else {
            return request
        }
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        return request
    }
    
}
