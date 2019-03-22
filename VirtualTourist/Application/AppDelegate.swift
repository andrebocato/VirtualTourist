//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 15/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//
// @TODO: properly implement data model entities details and properties
// @TODO: set up relationship between entities


import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK; - Properties
    
    var window: UIWindow?
    let dataController = DataController()

    // MARK: - Life Cycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        dataController.load()
        
        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationsViewController = navigationController.topViewController as! TravelLocationsViewController
        travelLocationsViewController.dataController = dataController
        
        return true
    }

//    func applicationWillResignActive(_ application: UIApplication) {
//    }

//    func applicationDidEnterBackground(_ application: UIApplication) {
//    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        saveContext()
    }

//    func applicationDidBecomeActive(_ application: UIApplication) {
//    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "VirtualTourist")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    private func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Functions
    
    func saveViewContext() {
        try? dataController.viewContext.save()
    }
    
}

