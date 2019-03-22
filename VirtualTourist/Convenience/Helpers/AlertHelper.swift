//
//  AlertHelper.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 18/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation
import UIKit

class AlertHelper {
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Functions
    
    static func showAlert(inController controller: UIViewController,
                          title: String,
                          message: String,
                          rightAction: UIAlertAction? = nil,
                          onCompletion: (() -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if rightAction == nil {
                alert.dismiss(animated: true, completion: nil)
            } else {
                onCompletion?()
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(okAction)
        if let rightAction = rightAction {
            alert.addAction(rightAction)
        } else {
            alert.addAction(cancelAction)
        }
        
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: nil)
        }
        
    }
}
