//
//  AlbumViewController.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 03.07.15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var labelText: UILabel!
    
    var pin: Pin!
    
    override func viewDidLoad() {
        if pin.photos.count == 0 && pin.urls.count == 0 {
            self.labelText.hidden = false
            collectionView.hidden = true
            barButton.enabled = false
        }
        
        super.viewDidLoad()
        
        //Set up collection View
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        
        //perform the fetch and config fetchcontroller
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        
        //MARK: Set up initial MapView
        
        let region = MKCoordinateRegionMakeWithDistance(pin!.coordinate, 10000, 10000)
        let adjustedRegion = mapView.regionThatFits(region)
        mapView.setRegion(adjustedRegion, animated: true)
        mapView.addAnnotation(pin)
        
        //set up the barButton
        barButton.target = self
        barButton.action = "newCollection"
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //several functions will be called with notifications, to ensure smooth download of pictures in the background.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadData", name: "imageLoaded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enableButton", name: "downloadComplete", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "disableButton", name: "downloadStarted", object: nil)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        println(pin.photos.count)
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! FlickrViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.imageView.image = photo.image
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //change button title according to function
        if collectionView.indexPathsForSelectedItems().count > 0 {
            barButton.title = "Delete Items"
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        //change button title according to function
        if collectionView.indexPathsForSelectedItems().count == 0 {
            barButton.title = "New Collection"
        }
    }
    
    func newCollection () {
        let indexArray = collectionView.indexPathsForSelectedItems() as! [NSIndexPath]
        if indexArray.count != 0 {
            //Array needs to be sorted descendingly. Otherwise app will crash due to index mis match
            let sortedArray = indexArray.sorted{$0.row > $1.row}
            for indexPath in sortedArray {
                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
                sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        } else {
            //otherwise delete all the photos contained in the pin
            for photo in pin.photos {
                sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            let notification = NSNotification(name: "downloadStarted", object: nil)
            NSNotificationCenter.defaultCenter().postNotification(notification)
            if pin.urls.count != 0 {
                let minimum: Int = min(pin.urls.count, 20)
                for i in 0..<minimum {
                    //choose a random url, assign it to a photo and then delete that url object from our Pin.
                    let randomURL = pin.urls[Int(arc4random_uniform(UInt32(pin.urls.count)))]
                    let coreImage = Photo(photoUrl: randomURL.urlString, assignedPin: pin, context: self.sharedContext)
                    self.sharedContext.deleteObject(randomURL)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                //place the downloading task on a background thread so the images can load
                dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)) {
                    for photo in self.pin.photos {
                        photo.image = ImageClient.sharedInstance().downloadImage(photo.urlString, path: photo.path)
                        let notification = NSNotification(name: "imageLoaded", object: nil)
                        NSNotificationCenter.defaultCenter().postNotification(notification)
                    }
                    let notification = NSNotification(name: "downloadComplete", object: nil)
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
                switch type {
                case .Insert:
                    if collectionView.hidden {
                        collectionView.hidden = false
                        labelText.hidden = true
                    }
                    collectionView.reloadData()
                case .Delete:
                    collectionView.performBatchUpdates({
                        self.collectionView.deselectItemAtIndexPath(indexPath, animated: false)
                        self.collectionView.deleteItemsAtIndexPaths([indexPath!])
                        return
                        }, completion: {success in
                            // in case there are no more urls and therefore pictures for this location, hide the collection view and tell user to download new photos
                            if success {
                                if self.pin?.photos.count == 0 && self.pin.urls.count == 0 {
                                    self.labelText.hidden = false
                                    self.collectionView.hidden = true
                                    self.labelText.text = "No more images at this location. Place a new pin"
                                }
                            }
                    })
                default:
                    return
                }
    }
    
    
    //MARK: Notifications functions
    //gets called when a new picture is downloaded
    func reloadData () {
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadSections(NSIndexSet(index: 0))
        })
    }
    
    //disables the Button when pictures are being downloaded
    func disableButton () {
        dispatch_async(dispatch_get_main_queue(), {
            //disable animations to stop flickering while downloading images
            UIView.setAnimationsEnabled(false)
            self.barButton.enabled = false
        })
    }
    
    //this function enables the bar button once the download of images has finished
    func enableButton () {
        dispatch_async(dispatch_get_main_queue(), {
            self.barButton.enabled = true
            UIView.setAnimationsEnabled(true)
        })
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "path", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        }()
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //unsubscribe from notifications
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "imageLoaded", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "downloadComplete", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "downloadStarted", object: nil)
    }
    
}