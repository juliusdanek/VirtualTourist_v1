//
//  ImageClient.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 08.07.15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import Foundation
import UIKit

class ImageClient: NSObject {
    
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        
        //Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    
    func storeImage(image: UIImage?, identifier: String) {
        
        let path = pathForIdentifier(identifier)
        
        //if image is nil - delete from documents directory
        if image == nil {
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            return
        }
        
        //needs to be converted here for Photo entity to have a variable title image of type UIImage
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        imageData.writeToFile(path, atomically: true)
    }
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier+".jpg")
        
        return fullURL.path!
    }
    
    func downloadImage(urlString: String, path: String) -> UIImage {
        let url = NSURL(string: urlString)
        let photoData = NSData(contentsOfURL: url!)
        let photo = UIImage(data: photoData!)
        self.storeImage(photo, identifier: path)
        return photo!
    }

    
    func loadImageFromUrl (url: NSURL) {
        
        
    }
    
    //    - (void) loadImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholder cachingKey:(NSString*)key {
    //    self.imageURL = url;
    //    self.image = placeholder;
    //    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    //    dispatch_async(queue, ^{
    //    NSData *data = [NSData dataWithContentsOfURL:url];
    //
    //    UIImage *imageFromData = [UIImage imageWithData:data];
    //
    //    [FTWCache setObject:UIImagePNGRepresentation(imageFromData) forKey:key];
    //    UIImage *imageToSet = imageFromData;
    //    if (imageToSet) {
    //    if ([self.imageURL.absoluteString isEqualToString:url.absoluteString]) {
    //				dispatch_async(dispatch_get_main_queue(), ^{
    //    self.image = imageFromData;
    //				});
    //    }
    //    }
    //    self.imageURL = nil;
    //    });
    //}
    
    
    
    class func sharedInstance() -> ImageClient {
        struct Singleton {
            static let sharedInstance = ImageClient()
        }
        return Singleton.sharedInstance
    }
    
}
