//
//  Photo.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 03.07.15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)


class Photo: NSManagedObject {
    
    @NSManaged var path: String
    @NSManaged var pin: Pin?
    
    var image: UIImage {
        
        get {
            
        }
        
        set {
            
        }
    }
    
    
}