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

class AlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var photoAlbum: [NSURL]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        if photoAlbum == nil {
            collectionView.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if photoAlbum == nil {
            return 0
        } else {
            return min(photoAlbum!.count, 20)
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! FlickrViewCell
        
        
        let imageData = NSData(contentsOfURL: photoAlbum![indexPath.row])
        
        cell.imageView.image = UIImage(data: imageData!)
        
        return cell
        
    }
    
    
}