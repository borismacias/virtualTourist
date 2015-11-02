//
//  Photo.swift
//  virtualTourist
//
//  Created by Boris Alexis Gonzalez Macias on 7/27/15.
//  Copyright (c) 2015 PropiedadFacil. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    
    @NSManaged var imageName: String
    @NSManaged var pin: Pin
    
    // MARK: - Storing URL to async download the photos
    @NSManaged var flickrURL: String
    
    // MARK: - CoreData init
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageName:String,flickrURL:String,pin: Pin, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imageName = imageName
        self.pin = pin
        self.flickrURL = flickrURL
    }
    
    // MARK: - Convenience methods
    func image() -> UIImage?{
        print(self.imageURL())
        return UIImage(contentsOfFile: self.imageURL())
    }
    
    func imageURL() -> String{
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileURL = NSURL.fileURLWithPathComponents([dirPath, self.imageName])
        return fileURL!.path!
    }
    
    override func prepareForDeletion() {
        let fileURL = NSURL.fileURLWithPath(self.imageURL(), isDirectory: false)
        do{
            try NSFileManager.defaultManager().removeItemAtURL(fileURL)
        }catch{
        }
    }
    
    
}
