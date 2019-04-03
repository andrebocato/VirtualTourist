//
//  URLRequest+Extension.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 18/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

extension URLRequest {
    
    @discardableResult
    private func dispatchRequest(onCompletion: @escaping (ServiceResponse) -> Void) -> URLSessionDataTask {
        
        let task = URLSession.shared.dataTask(with: self) { (data, response, error) in
            var serviceResponse = ServiceResponse()
            
            serviceResponse.data = data
            serviceResponse.response = response as? HTTPURLResponse
            serviceResponse.request = self
            
            if let data = data {
                serviceResponse.rawResponse = String(data: data, encoding: .utf8)
            }
            
            guard let statusCode = serviceResponse.response?.statusCode else { return }
            if !(200...299 ~= statusCode) {
                ErrorHelper.logServiceError(.statusCode)
            }
            
            onCompletion(serviceResponse)
        }
        
        task.resume()
        
        return task
    }
    
    /// Use this method when service payload doesn't need to be serialized.
    func treatResponse(onSuccess: @escaping (ServiceResponse) -> Void,
                       onFailure: @escaping (ServiceResponse) -> Void,
                       onCompletion: @escaping () -> Void) -> URLSessionDataTask {
        
        return dispatchRequest(onCompletion: { (serviceResponse) in
            if serviceResponse.errorResponse != nil {
                onFailure(serviceResponse)
            } else {
                onSuccess(serviceResponse)
            }
            
            DispatchQueue.main.async {
                onCompletion()
            }
        })
    }
    
    /// Used this method to serialize service payload.
    func treatResponse<SuccessObjectType: Codable>(onSuccess: @escaping (SuccessObjectType?, ServiceResponse) -> Void,
                                                   onFailure: @escaping (ServiceResponse) -> Void,
                                                   onCompletion: @escaping () -> Void) {
        
        dispatchRequest(onCompletion: { (serviceResponse) in
            if serviceResponse.errorResponse != nil {
                onFailure(serviceResponse)
            } else {
                if let data = serviceResponse.data {
                    do {
                        let serializedObject = try JSONDecoder().decode(SuccessObjectType.self, from: data)
                        onSuccess(serializedObject, serviceResponse)
                    } catch {
                        ErrorHelper.logSerializationError(.failedToSerialize)
                        onSuccess(nil, serviceResponse)
                    }
                } else {
                    onSuccess(nil, serviceResponse)
                }
            }
            
            DispatchQueue.main.async {
                onCompletion()
            }
        })
        
    }
}
