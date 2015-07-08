//
//  VTClient.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 02.07.15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import Foundation
import UIKit

class VTClient: NSObject {
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    
    struct constants {
        static let baseURL = "https://api.flickr.com/services/rest/"
        static let methodName = "flickr.photos.search"
        static let api_key = "d925dfaa76dcf97e47504ab567edf4be"
        static let extras = "url_q"
        static let media = "photos"
        static let format = "json"
        static let nojsoncallback = "1"
    }
    
    
    func getPageNumber (latitude: Double, longitude: Double, completionHandler: (success: Bool, imageArray: [[String: AnyObject]]?, errorString: String?) -> Void) {
        
        //parameters for call
        var parameterDict: [String: String] = [
            "method": constants.methodName,
            "api_key" : constants.api_key,
            "extras" : constants.extras,
            "media" : constants.media,
            "bbox" : createBoundingBoxString(latitude, longitude: longitude),
            "format" : constants.format,
            "nojsoncallback" : constants.nojsoncallback,
        ]

        let url = NSURL(string: (constants.baseURL + escapedParameters(parameterDict)))
        
        let request = NSURLRequest(URL: url!)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                completionHandler(success: false, imageArray: nil, errorString: "Could not download data from server")
            } else {
                VTClient.parseJSONWithCompletionHandler(data, completionHandler: {result, error in
                    if error != nil {
                        completionHandler(success: false, imageArray: nil, errorString: "Could not parse data")
                    } else {
                        //data format comes back in dictionary with photos
                        if let photos = result["photos"] as? NSDictionary {
//                            println(photos)
                            //TODO: Check for that in completion Handler call
                            //check whether the total number of photos is zero, if yes then we have a case of no pictures at that location
                            if photos["total"] as! String == "0" {
                                completionHandler(success: true, imageArray: nil, errorString: nil)
                            } else if let photosData = photos["photo"] as? [[String: AnyObject]] {
//                                println(photosData)
                                var urlArray = [[String: AnyObject]]()
                                for photo in photosData {
                                    if let url = photo["url_q"] as? String {
                                        var photoDict = [String: AnyObject]()
                                        photoDict["url"] = (NSURL(string: url)!)
                                        photoDict["id"] = photo["id"] as! String
                                        urlArray.append(photoDict)
                                    }
                                }
                                completionHandler(success: true, imageArray: urlArray, errorString: nil)
                            }
                        }
                    }
                })
            }
            
            
        })
        
        task.resume()
        
    }
    
    
    
    //HELPER:
    //creating the BBOX necessary for the flickr API call
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        
        let bottom_left_lon = (longitude - 0.5)
        let bottom_left_lat = (latitude - 0.5)
        let top_right_lon = (longitude + 0.5)
        let top_right_lat = (latitude + 0.5)
        
//        println("\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)")
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    //HELPER:
    //escape function parameters
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    //HELPER: JSON parsing
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        var parsingError: NSError? = nil
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }

    
    //create Singleton of class
    class func sharedInstance() -> VTClient {
        struct Singleton {
            static let sharedInstance = VTClient()
        }
        return Singleton.sharedInstance
    }
    
}