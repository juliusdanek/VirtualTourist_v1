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
    @NSManaged var urlString: String
    @NSManaged var pin: Pin?
    
    var image: UIImage? {
        
        get {
            if let image = ImageClient.sharedInstance().imageWithIdentifier(path) {
                return image
            } else {
                return UIImage(named: "placeholder")
            }
        }
        set {
            //if the new value is nil, i.e. in the case of deletion, erase the picture from memory
            if newValue == nil {
                ImageClient.sharedInstance().storeImage(newValue, identifier: path)
            }
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoUrl: String, assignedPin: Pin, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        path = generatePathFromDate()
        
        image = UIImage(named: "placeholder")
        
        urlString = photoUrl
        
        pin = assignedPin
    }
    
    //setter method of image to nil -> results in deletion of picture as specified in ImageClient
    override func prepareForDeletion() {
        super.prepareForDeletion()
        image = nil
    }
    
    
    //Helper:
    //Generates unique path in documents directory
    func generatePathFromDate () -> String {
        let now = NSDate()
        
        var pathString :String = String(format:"%f", now.timeIntervalSince1970)
        return pathString
    }

    
    
}