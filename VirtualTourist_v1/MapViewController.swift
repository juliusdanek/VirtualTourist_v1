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
            
            VTClient.sharedInstance().getPageNumber(pin.latitude as Double, longitude: pin.longitude as Double, completionHandler: {success, photoArray, error in
                    if success {
                        if let photos = photoArray {
                            let minimum: Int = min(photos.count, 20)
                            for i in 0..<minimum {
                                let randomIndex = Int(arc4random_uniform(UInt32(photos.count)))
                                let photoData = NSData(contentsOfURL: photos[randomIndex]["url"] as! NSURL)
                                let blablaPhoto = UIImage(data: photoData!)
                                let id = photos[randomIndex]["id"] as! String
                                let coreImage = Photo(docPath: id, context: self.sharedContext)
                                println(blablaPhoto)
                                coreImage.image = blablaPhoto!
//                                image.pin = pin
                            }
                        }
                }
            })
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            
            
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
//            VTClient.sharedInstance().getPageNumber(view.annotation.coordinate.latitude, longitude: view.annotation.coordinate.longitude, completionHandler: {success, photoArray, error in
//                if success {
//                    dispatch_async(dispatch_get_main_queue(), {
//                        let avc = self.storyboard?.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
//                        avc.photoAlbum = photoArray
//                        //deselect the annotation so it can be deleted once coming back to main mapView
//                        mapView.deselectAnnotation(view.annotation, animated: false)
//                        self.navigationController?.pushViewController(avc, animated: true)
//                    })
//                }
//            })
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        //saving the context here as it crashes in didSelectAnnotationView
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //MARK: Trying to drag and drop the fucking pin
    
//    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
//        
//        if let annotationView = views[0] as? MKAnnotationView {
//            annotationView.setDragState(MKAnnotationViewDragState.Starting, animated: true)
//        }
//    }
    
//    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
//        
//        if (oldState == .Starting && newState == .Ending) {
//            println("Ending drag")
//        }
//        
//        if newState == MKAnnotationViewDragState.Ending {
//            var droppedAt: CLLocationCoordinate2D = view.annotation.coordinate
//            
//            println(droppedAt.latitude + droppedAt.longitude)
//        }
//    }
    
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

