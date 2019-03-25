//
//  DataController.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 20/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    // MARK: - Enums
    
    enum CoreDataContext {
        case view
        case background
    }
    
    // MARK: - Initialization
    
    init(modelName: String!) {
        persistentContainer = NSPersistentContainer(name: modelName)
        backgroundContext = persistentContainer.newBackgroundContext()
    }
        
    // MARK: - Properties
    
    let persistentContainer: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext!
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Functions
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext(interval: 3)
            self.configureContexts()
            completion?()
        }
    }
    
    func saveViewContext() {
        
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch let error {
                debugPrint("error: \(error.localizedDescription)")
            }
        }
        
    }
    
}
