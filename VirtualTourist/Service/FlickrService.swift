//
//  FlickrService.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 18/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation
import CoreLocation

class FlickrService {
    
    // MARK: - Networking Functions
    
    /// Searches for an an album on given coordinate using the FickrAPI.
    func searchAlbum(inCoordinate coordinate: CLLocationCoordinate2D? = nil,
                     page: Int = 1,
                     onSuccess succeeded: @escaping ((_ albumResponse: AlbumSearchResponse?) -> Void),
                     onFailure failed: ((Error?) -> Void)? = nil,
                     onCompletion completed: (() -> Void)? = nil) {
    
        let urlString = createUrl(with: coordinate, page: page)
        let url = URL(string: urlString)
        
        Service.shared.request(httpMethod: .get, url: url!).treatResponse(onSuccess: { (albumSearchResponse: AlbumSearchResponse?, serviceResponse) in
            guard let status = albumSearchResponse?.status, status == FlickrConstants.ResponseValues.okStatus else {
                guard let code = albumSearchResponse?.code, let message = albumSearchResponse?.message else {
                    failed?(ServiceError.flickrApi /* gives an error of type flickrApi */)
                    return
                }
                failed?(ErrorResponse(code: code, message: message) /* gives an error using 'code' and 'message' from response */)
                return
            }
            succeeded(albumSearchResponse)
            
        }, onFailure: { (serviceResponse) in
            failed?(serviceResponse.errorResponse)
            
        }) {
            completed?()
        }

        
    }
    
    /// GETs a photo's data from a given URL.
    func getPhotoData(fromURL url: String,
                  onSuccess succeeded: @escaping ((_ imageData: Data?) -> Void),
                  onFailure failed: ((Error?) -> Void)? = nil,
                  onCompletion completed: (() -> Void)? = nil) {
        
        let url = URL(string: url)
        
        let task = Service.shared.request(httpMethod: .get, url: url!).treatResponse(onSuccess: { (serviceResponse) in
            succeeded(serviceResponse.data)
        }, onFailure: { (serviceResponse) in
            failed?(serviceResponse.errorResponse)
        }) {
            completed?()
        }
        
        task.resume()
    }

    // MARK: - Helper Functions
    
    private func createUrl(with coordinate: CLLocationCoordinate2D? = nil,
                           page: Int = 1) -> String {
        
        func createBoundingBoxString(from coordinate: CLLocationCoordinate2D? = nil) -> String {
            
            guard let latitude = coordinate?.latitude, let longitude = coordinate?.longitude else { return "0,0,0,0" }
            
            let minimumLongitude = max(longitude - FlickrConstants.searchBBoxHalfWidth, FlickrConstants.searchLonRange.0)
            let minimumLatitude = max(latitude - FlickrConstants.searchBBoxHalfHeight, FlickrConstants.searchLatRange.0)
            let maximumLongitude = min(longitude + FlickrConstants.searchBBoxHalfWidth, FlickrConstants.searchLonRange.1)
            let maximumLatitude = min(latitude + FlickrConstants.searchBBoxHalfHeight, FlickrConstants.searchLatRange.1)
            
            return "\(minimumLongitude),\(minimumLatitude),\(maximumLongitude),\(maximumLatitude)"
        }
        
        let methodParameters: [String: String] = [
            FlickrConstants.ParameterKeys.method: FlickrConstants.ParameterValues.searchMethod,
            FlickrConstants.ParameterKeys.apiKey: FlickrConstants.flickrRestApiKey,
            FlickrConstants.ParameterKeys.boundingBox: createBoundingBoxString(from: coordinate),
            FlickrConstants.ParameterKeys.safeSearch: FlickrConstants.ParameterValues.useSafeSearch,
            FlickrConstants.ParameterKeys.extras: FlickrConstants.ParameterValues.mediumURL,
            FlickrConstants.ParameterKeys.format: FlickrConstants.ParameterValues.responseFormat,
            FlickrConstants.ParameterKeys.noJSONCallback: FlickrConstants.ParameterValues.disableJSONCallback,
            FlickrConstants.ParameterKeys.perPage: FlickrConstants.ParameterValues.perPage,
            FlickrConstants.ParameterKeys.page: "\(page)"
        ]
        
        return FlickrConstants.flickrBaseURL + URLHelper.escapedParameters(from: methodParameters)
    }
    
}
