//
//  FlickrViewCell.swift
//  VirtualTourist_v1
//
//  Created by Julius Danek on 03.07.15.
//  Copyright (c) 2015 Julius Danek. All rights reserved.
//

import Foundation
import UIKit

class FlickrViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    //custom getter and setter methods for selected, modifying the appearance when an item is selected. 
    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            if newValue {
                println("selected")
                super.selected = true
                self.imageView.alpha = 0.5
            } else if newValue == false {
                println("deslected")
                super.selected = false
                self.imageView.alpha = 1.0
            }
        }
    }
    
}
