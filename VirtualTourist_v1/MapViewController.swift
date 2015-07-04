//
//  ViewController.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 02.07.15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //see if mapDict exists, if yes then set span and center of region accordinngly
        //MARK: For some reason the span is never set correctly, it simply doesn't work even though it saves it
        if let mapDict = NSUserDefaults.standardUserDefaults().objectForKey("mapDict") as? [String: Double] {
            let mapRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(mapDict["lat"]!, mapDict["long"]!), MKCoordinateSpanMake(mapDict["latDelta"]!, mapDict["longDelta"]!))
            mapView.setRegion(mapRegion, animated: false)
        }

        //iniate longpress gesture recognizer with target self and that induces pin drop
        var longPress = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        
        mapView.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
    
        let annotation = MKPointAnnotation()
    
        if UIGestureRecognizerState.Began == gestureRecognizer.state {
            annotation.coordinate = touchMapCoordinate
            mapView.addAnnotation(annotation)
            
        }
        
        if UIGestureRecognizerState.Ended == gestureRecognizer.state {
            
            annotation.coordinate = touchMapCoordinate
        }
        
        
    }
    
    //saving changing values in user default dict. However, span does not accurately work. 
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        let mapDict = [
            "lat" : mapView.region.center.latitude,
            "long" : mapView.region.center.longitude,
            "latDelta": mapView.region.span.latitudeDelta,
            "longDelta": mapView.region.span.longitudeDelta
        ]
        NSUserDefaults.standardUserDefaults().setObject(mapDict, forKey: "mapDict")
        
        
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        let annotation = view.annotation
        
        VTClient.sharedInstance().getPageNumber(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, completionHandler: {success, photoArray, error in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    let avc = self.storyboard?.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
                    avc.photoAlbum = photoArray
                    self.navigationController?.pushViewController(avc, animated: true)
                })
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let avc = segue.destinationViewController as! AlbumViewController
        

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
    


}

