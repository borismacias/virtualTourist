//
//  TravelLocationsViewController.swift
//  virtualTourist
//
//  Created by Boris Alexis Gonzalez Macias on 7/26/15.
//  Copyright (c) 2015 PropiedadFacil. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedPin : Pin!
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        return url!.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do{
            try self.fetchedResultsController.performFetch()
        }catch {}

        self.fetchedResultsController.delegate = self
        self.mapView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        // MARK: - Restoring old map appearance 
        
        restoreMapRegion(animated)
        let pins = fetchedResultsController.fetchedObjects!
        for p in pins {
            let pin = p as! Pin
            self.mapView.addAnnotation(pin)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    @IBAction func createPin(sender: UILongPressGestureRecognizer) {
        // MARK: - Filtering the states to only set the pin at the start of the event
        if sender.state == UIGestureRecognizerState.Began {
            let touchPoint = sender.locationInView(self.mapView)
            let coordinate = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            let location:[String:AnyObject] = ["lat":Double(coordinate.latitude), "lng": Double(coordinate.longitude)]
            let pin = Pin(locationDict: location, context: self.sharedContext)
            mapView.addAnnotation(pin)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }

    // MARK: - Mapviewdelegate functions
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = self.mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        self.selectedPin = view.annotation as! Pin
        performSegueWithIdentifier("showPhotoViewCollection", sender: self)
    }

    // MARK: - Saving the map state on region change
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showPhotoViewCollection" )
        {
            let destinationView = segue.destinationViewController as! PhotoAlbumViewController
            destinationView.pin = self.selectedPin
            
        }
        
    }
    
    // MARK: - Functions to save and restore the map status
    func saveMapRegion() {
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }

}

