//
//  ViewController.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 02.07.15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        //see if mapDict exists, if yes then set span and center of region accordinngly
        //MARK: For some reason the span is never set correctly, it simply doesn't work even though it saves it
        if let mapDict = NSUserDefaults.standardUserDefaults().objectForKey("mapDict") as? [String: Double] {
            let mapRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(mapDict["lat"]!, mapDict["long"]!), MKCoordinateSpanMake(mapDict["latDelta"]!, mapDict["longDelta"]!))
            mapView.setRegion(mapRegion, animated: false)
        }
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //Fetch the pins:
        fetchedResultsController.performFetch(nil)
        
        let pinArray: [Pin] = fetchedResultsController.fetchedObjects as! [Pin]
        for pin in pinArray {
            mapView.addAnnotation(pin)
        }

        
        //iniate longpress gesture recognizer with target self and that induces pin drop
        var longPress = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        
        mapView.delegate = self
        
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
        
        if UIGestureRecognizerState.Began == gestureRecognizer.state {
            let pin = Pin(annotationLatitude: touchMapCoordinate.latitude, annotationLongitude: touchMapCoordinate.longitude, context: sharedContext)
            mapView.addAnnotation(pin)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            //this entire function is executed on a background thread, allowing for the download of pictures in the background
            //download picture as a function of latitude and longitude coordinates
            VTClient.sharedInstance().getPageNumber(pin.latitude as Double, longitude: pin.longitude as Double, completionHandler: {success, photoArray, error in
                    let notification = NSNotification(name: "downloadStarted", object: nil)
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                    if success {
                        //if successful, first save all the urls as url objects and assign them to the pin
                        if let photos = photoArray {
                            for photo in photos {
                                let url = URL(stringURL: photo, assignedPin: pin, context: self.sharedContext)
                            }
                            //then choose twenty random urls and initiate photo objects from them
                            let minimum: Int = min(pin.urls.count, 20)
                            for i in 0..<minimum {
                                //choose a random url, assign it to a photo and then delete that url object from our Pin.
                                let randomURL = pin.urls[Int(arc4random_uniform(UInt32(pin.urls.count)))]
                                let coreImage = Photo(photoUrl: randomURL.urlString, assignedPin: pin, context: self.sharedContext)
                                self.sharedContext.deleteObject(randomURL)
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                            for photo in pin.photos {
                                photo.image = ImageClient.sharedInstance().downloadImage(photo.urlString, path: photo.path)
                                let notification = NSNotification(name: "imageLoaded", object: nil)
                                NSNotificationCenter.defaultCenter().postNotification(notification)
                            }
                            let notification = NSNotification(name: "downloadComplete", object: nil)
                            NSNotificationCenter.defaultCenter().postNotification(notification)
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                }
            })
        }
    }
    
    //saving changing values in user default dict. However, span does not accurately work. Multiplied span by 0.99 to adjust for snapping out of zoom levels in MapKit
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        let mapDict = [
            "lat" : mapView.region.center.latitude,
            "long" : mapView.region.center.longitude,
            "latDelta": mapView.region.span.latitudeDelta*0.99,
            "longDelta": mapView.region.span.longitudeDelta*0.99
        ]
        NSUserDefaults.standardUserDefaults().setObject(mapDict, forKey: "mapDict")
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if self.editing == true {
            //delete the object from the shared context
            sharedContext.deleteObject(view.annotation as! Pin)
            //remove the annotation
            mapView.removeAnnotation(view.annotation)
        } else {
            let avc = self.storyboard?.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
            let pin = view.annotation as! Pin
            avc.pin = pin
            //deselect the annotation so it can be deleted once coming back to main mapView
            mapView.deselectAnnotation(view.annotation, animated: false)
            self.navigationController?.pushViewController(avc, animated: true)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            navigationController?.setToolbarHidden(false, animated: true)
        } else {
            navigationController?.setToolbarHidden(true, animated: true)
        }
        //saving the context here as it crashes in didSelectAnnotationView
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("annotation") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
            annotationView?.pinColor = .Purple
            annotationView?.animatesDrop = true
            annotationView?.draggable = true
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
        
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
}

