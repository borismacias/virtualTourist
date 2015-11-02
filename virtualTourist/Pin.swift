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
    
    // MARK: - Parameter to fulfill mkkannotation class
    var coordinate: CLLocationCoordinate2D {
        return calculatedCoordinate!
    }
    // MARK: - CoreData init
    
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
    
     var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    func getCollection(pageNumber: Int,completionHandler : (success:Bool) -> Void){
        
        let resource = "/?method=flickr.photos.search"
        let parameters = ["lat": self.coordinate.latitude, "lon": self.coordinate.longitude, "page": pageNumber]
        
        Flicker.sharedInstance().taskForResource(resource, parameters: parameters as! [String : AnyObject] ){ JSONResult, error  in
            if let error = error {
                print(error)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    if let photosDictionaries = JSONResult.valueForKey("photos")!.valueForKey("photo") as? [[String : AnyObject]] {
                        // Parse the array of photos dictionaries
                        let _ = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Void in
                            
                            let photoURL = Flicker.sharedInstance().buildUrlFromDictionary(dictionary)
                            let fileName = NSURL(fileURLWithPath: photoURL).lastPathComponent
                            _ = Photo(imageName: fileName!,flickrURL: photoURL , pin: self, context: self.sharedContext)
                            CoreDataStackManager.sharedInstance().saveContext()
                            completionHandler(success: true)
                            
                        }
                        
                    }
                }
            }
        }
    }
}
