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
    
    var pin: Pin!
    
    override func viewDidLoad() {
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
        
        self.navigationItem.rightBarButtonItem = editButtonItem()
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadData", name: "imageLoaded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enableButton", name: "downloadComplete", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "disableButton", name: "downloadStarted", object: nil)
    }
    
    
    //MARK: To delete: Select multiple things. For each selection, add into array of indexPaths. When pressing delete, instantiate objects and delete them. COnfigure fetchresults in a view that changes are automatically displayed.
//    override func setEditing(editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//        if editing {
//            collectionView.select(FlickrViewCell)
//        }
//        
//    }
    
    
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
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

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
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
                switch type {
                
                case .Insert:
                    collectionView.reloadData()
                case .Delete:
                    collectionView.performBatchUpdates({
                        self.collectionView.deselectItemAtIndexPath(indexPath, animated: false)
                        self.collectionView.deleteItemsAtIndexPaths([indexPath!])
                        return
                        }, completion: {success in
                            if success {
                                if self.pin?.photos.count == 0 {
                                    self.collectionView.hidden = true
                                }
                            }
                    })
                default:
                    return
                }
    }
    
    func reloadData () {
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadSections(NSIndexSet(index: 0))
        })
    }
    
    func disableButton () {
        dispatch_async(dispatch_get_main_queue(), {
            self.barButton.enabled = false
            //disable animations to stop flickering while downloading images
            UIView.setAnimationsEnabled(false)
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
    
    
    
}