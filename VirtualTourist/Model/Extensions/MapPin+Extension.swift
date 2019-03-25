//
//  MapPin+Extension.swift
//  VirtualTourist
//
//  Created by Andre Sanches Bocato on 25/03/19.
//  Copyright © 2019 Andre Sanches Bocato. All rights reserved.
//

import Foundation

extension MapPin {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
}
