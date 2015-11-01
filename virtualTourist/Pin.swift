//
//  Pin.swift
//  virtualTourist
//
//  Created by Boris Alexis Gonzalez Macias on 7/26/15.
//  Copyright (c) 2015 PropiedadFacil. All rights reserved.
//

import MapKit
import CoreData

class Pin: NSManagedObject, MKAnnotation {
   
    @NSManaged var lat: Double
    @NSManaged var lng: Double
    @NSManaged var photos: [Photo]
    
    var calculatedCoordinate : CLLocationCoordinate2D? = nil
    
    var coordinate: CLLocationCoordinate2D {
        return calculatedCoordinate!
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        calculatedCoordinate = CLLocationCoordinate2DMake(lat, lng)
    }
    
    init(locationDict:[String:AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        lat = locationDict["lat"] as! Double
        lng = locationDict["lng"] as! Double
        
        self.calculatedCoordinate = CLLocationCoordinate2DMake(lat, lng)
    }
}
