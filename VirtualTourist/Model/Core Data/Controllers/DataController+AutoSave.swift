//
//  DataController+AutoSave.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 20/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

extension DataController {
    
    // MARK: - Auto Saving Function
    
    func autoSaveViewContext(interval: TimeInterval = 30) {
        debugPrint("Auto saving view context")
        
        guard interval > 0 else { return }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
    
}
