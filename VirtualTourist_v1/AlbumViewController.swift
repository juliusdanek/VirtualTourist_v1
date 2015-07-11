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
//        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
//        sharedContext.deleteObject(photo)
//        
//        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

    }
    
    func newCollection () {
        if collectionView.indexPathsForSelectedItems().count != 0 {
            for indexPath in collectionView.indexPathsForSelectedItems() {
                let photo = fetchedResultsController.objectAtIndexPath(indexPath as! NSIndexPath) as! Photo
//                self.collectionView.deselectItemAtIndexPath(indexPath as? NSIndexPath, animated: false)
                sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
//        for photo in pin.photos {
//            sharedContext.deleteObject(photo)
//            CoreDataStackManager.sharedInstance().saveContext()
//        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
                switch type {
                
                case .Insert:
                    collectionView.reloadData()
                case .Update:
                    println("updating")
                case .Delete:
                    collectionView.performBatchUpdates({
                        self.collectionView.deleteItemsAtIndexPaths([indexPath!])
                        self.collectionView.deselectItemAtIndexPath(indexPath, animated: false)
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
//            self.collectionView.performBatchUpdates({
//                self.collectionView.reloadSections(NSIndexSet(index: 0))
//                return
//                }, completion: {success in
//                    if success{
//                        println("update complete")
//                    }
//            })
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