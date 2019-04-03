//
//  DataController+PersistedPhotoManager.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 25/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation
import CoreData

extension DataController {
    
    // MARK: - Functions
    
    /// Creates a PersistedPhoto in Core Data using a FlickrPhoto.
    func createPersistedPhoto(from flickrPhoto: FlickrPhoto,
                              for mapPin: MapPin,
                              inContext context: NSManagedObjectContext) -> PersistedPhoto {
        
        let persistedPhoto = PersistedPhoto(context: context)
        
        persistedPhoto.id = flickrPhoto.id
        persistedPhoto.owner = flickrPhoto.owner
        persistedPhoto.secret = flickrPhoto.secret
        persistedPhoto.server = flickrPhoto.server
        persistedPhoto.farm = NSNumber(value: flickrPhoto.farm ?? 0).int32Value
        persistedPhoto.title = flickrPhoto.title
        persistedPhoto.title = flickrPhoto.title
        persistedPhoto.isPublic = flickrPhoto.isPublic == 1
        persistedPhoto.isFriend = flickrPhoto.isFriend == 1
        persistedPhoto.isFamily = flickrPhoto.isFamily == 1
        persistedPhoto.mapPin = mapPin
        
        return persistedPhoto
    }
    
    /// Converts an array of FlickrPhoto´s into an array of PersistedPhoto´s and persists it to Core Data assigning it to a MapPin.
    func convertAndPersist(_ flickrPhotos: [FlickrPhoto],
                           mapPin: MapPin,
                           context: CoreDataContext = .background,
                           onSuccess succeeded: @escaping ((_ persistedPhotos: [PersistedPhoto]) -> Void),
                           onFailure failed: ((PersistenceError?) -> Void)? = nil,
                           onCompletion completed: (() -> Void)? = nil) {
        
        let currentContext: NSManagedObjectContext = context == .background ? backgroundContext : viewContext
        
        currentContext.perform {
            
            var persistedPhotos = [PersistedPhoto]()
            
            // Converting flickr photos into persisted photos
            for flickrPhoto in flickrPhotos {
                let persistedPhoto = self.createPersistedPhoto(from: flickrPhoto, for: mapPin, inContext: currentContext)
                persistedPhotos.append(persistedPhoto)
            }
            
            do {
                try currentContext.save()
                debugPrint("successfully persisted 'PersistedPhotos'")
                succeeded(persistedPhotos)
                
            } catch let error {
                debugPrint("context.save failed with error:\n\(error)")
                failed?(PersistenceError.failedToPersist)
            }
            
            completed?()
        }
    }
    
    /// Converts a FlickrPhoto into a PersistedPhoto and adds it to a MapPin.
    func addPersistedPhoto(_ flickrPhoto: FlickrPhoto,
                           mapPin: MapPin,
                           context: CoreDataContext = .background,
                           onSuccess succeeded: @escaping ((_ persistedPhoto: PersistedPhoto) -> Void),
                           onFailure failed: ((PersistenceError?) -> Void)? = nil,
                           onCompletion completed: (() -> Void)? = nil) {
        
        let currentContext: NSManagedObjectContext = context == .background ? backgroundContext : viewContext
        
        currentContext.perform {
            
            let persistedPhoto = PersistedPhoto(context: currentContext)
            
            persistedPhoto.id = flickrPhoto.id
            persistedPhoto.owner = flickrPhoto.owner
            persistedPhoto.secret = flickrPhoto.secret
            persistedPhoto.server = flickrPhoto.server
            persistedPhoto.farm = NSNumber(value: flickrPhoto.farm ?? 0).int32Value
            persistedPhoto.title = flickrPhoto.title
            persistedPhoto.title = flickrPhoto.title
            persistedPhoto.isPublic = flickrPhoto.isPublic == 1
            persistedPhoto.isFriend = flickrPhoto.isFriend == 1
            persistedPhoto.isFamily = flickrPhoto.isFamily == 1
            persistedPhoto.mapPin = mapPin
            
            guard let id = flickrPhoto.id else {
                failed?(PersistenceError.failedToFind)
                return
            }
            
            do {
                try currentContext.save()
                
                debugPrint("successfully persisted 'PersistedPhoto' with id = \(id)")
                succeeded(persistedPhoto)
                
            } catch let error {
                debugPrint("context.save() failed with error:\n\(error)")
                failed?(PersistenceError.failedToPersist)
            }
            
            completed?()
        }
    }
    
    /// Deletes a PersistedPhoto from Core Data using its ID.
    func deletePersistedPhoto(withID id: String,
                              context: CoreDataContext = .background,
                              onSuccess succeeded: @escaping (() -> Void),
                              onFailure failed: ((PersistenceError?) -> Void)? = nil,
                              onCompletion completed: (() -> Void)? = nil) {
        
        let currentContext: NSManagedObjectContext = context == .background ? backgroundContext : viewContext
        
        currentContext.perform {
            
            self.getPersistedPhoto(withID: id, context: context, onSuccess: { (photo) in
                
                guard let photo = photo else {
                    debugPrint("could not find 'PersistedPhoto' with id = \(id)")
                    failed?(PersistenceError.failedToFind)
                    return
                }
                
                currentContext.delete(photo)
                do {
                    try currentContext.save()
                    debugPrint("sucessfully deleted 'PersistedPhoto' with id = \(id)")
                    succeeded()
                    
                } catch let error {
                    debugPrint("context.save() failed with error:\n\(error)")
                    failed?(PersistenceError.failedToDelete)
                }
                
            }, onFailure: failed, onCompletion: completed)
        }
    }
    
    /// Deletes an array of PersistedPhoto´s from Core Data.
    func deletePersistedPhotos(_ persistedPhotos: [PersistedPhoto],
                               context: CoreDataContext = .background,
                               onSuccess succeeded: @escaping (() -> Void),
                               onFailure failed: ((PersistenceError?) -> Void)? = nil,
                               onCompletion completed: (() -> Void)? = nil) {
        
        let currentContext: NSManagedObjectContext = context == .background ? backgroundContext : viewContext
        
        currentContext.perform {
            
            for persistedPhoto in persistedPhotos {
                currentContext.delete(persistedPhoto)
            }
            
            do {
                try currentContext.save()
                debugPrint("sucessfully deleted 'PersistedPhotos'")
                succeeded()
                
            } catch let error {
                debugPrint("context.save() failed with error:\n\(error)")
                failed?(PersistenceError.failedToPersist)
            }
            
            completed?()
        }
    }
    
    /// Fetches a PersistedPhoto from Core Data using its ID.
    func getPersistedPhoto(withID id: String,
                           context: CoreDataContext = .view,
                           onSuccess succeeded: @escaping ((_ photo: PersistedPhoto?) -> Void),
                           onFailure failed: ((PersistenceError?) -> Void)? = nil,
                           onCompletion completed: (() -> Void)? = nil) {
        
        let currentContext: NSManagedObjectContext = context == .background ? backgroundContext : viewContext
        
        currentContext.perform {
            
            let fetchRequest = NSFetchRequest<PersistedPhoto>(entityName: "PersistedPhoto")
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let result = try currentContext.fetch(fetchRequest)
                guard let persistedPhoto = result.first else {
                    debugPrint("could not find 'PersistedPhoto' with id = \(id)")
                    failed?(PersistenceError.failedToFind)
                    return
                }
                succeeded(persistedPhoto)
                
            } catch let error {
                debugPrint("getPersistedPhoto() failed with error:\n\(error)")
                failed?(PersistenceError.failedToFind)
            }
            
            completed?()
        }
    }
    
    /// Updates a PersistedPhoto's data using its objectID.
    func updatePersistedPhotoData(withObjectID objectID: NSManagedObjectID,
                                  data: Data,
                                  context: CoreDataContext = .background,
                                  onSuccess succeeded: @escaping (() -> Void),
                                  onFailure failed: ((PersistenceError?) -> Void)? = nil,
                                  onCompletion completed: (() -> Void)? = nil) {
        
        let currentContext: NSManagedObjectContext = context == .background ? backgroundContext : viewContext
        
        let persistedPhoto = currentContext.object(with: objectID) as! PersistedPhoto
        
        currentContext.perform {
            
            persistedPhoto.data = data
            
            do {
                try currentContext.save()
                debugPrint("sucessfully updated 'PersistedPhoto' data with id = \(objectID)")
                succeeded()
                
            } catch let error {
                debugPrint("context.save() failed with error:\n\(error)")
                failed?(PersistenceError.failedToPersist)
            }
            
            completed?()
        }
    }
    
}
