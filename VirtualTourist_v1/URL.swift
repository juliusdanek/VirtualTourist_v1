//
//  Url.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 7/11/15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(URL)

class URL: NSManagedObject {
    
    @NSManaged var urlString: String
    @NSManaged var photos: Photo?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(stringURL: String, assignedPin: Pin, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("URL", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        urlString = stringURL
        
        pin = assignedPin
    }
}
