//
//  PhotoAlbumViewController.swift
//  virtualTourist
//
//  Created by Boris Alexis Gonzalez Macias on 7/27/15.
//  Copyright (c) 2015 PropiedadFacil. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import MapKit

class PhotoAlbumViewController : UIViewController, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource {

    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noimages: UILabel!
    
    var pin: Pin!
    var pageNumber = 1
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultsController.delegate = self
        do{
            try self.fetchedResultsController.performFetch()
        }catch{}
    }
    
    @IBAction func getNewCollection(sender: AnyObject) {
        if(self.selectedIndexes.count==0){
            self.pageNumber++
            self.bottomButton.enabled = false
            for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
                self.sharedContext.deleteObject(photo)
            }
            self.getCollection()
            self.bottomButton.enabled = true
        }
        else{
            for index in self.selectedIndexes {
                let photo = self.fetchedResultsController.objectAtIndexPath(index) as! Photo
                self.sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
        }
        selectedIndexes = [NSIndexPath]()
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateBottomButton()
        removePins()
        self.mapView.addAnnotation(pin)
        centerMap()
        
        if self.fetchedResultsController.fetchedObjects!.count == 0 {
            
            self.getCollection()
            
        }
        
    }
    
    func removePins(){
        let annotations = self.mapView.annotations
            for _annotation in annotations {
                if let annotation = _annotation as MKAnnotation?
                {
                    self.mapView.removeAnnotation(annotation)
                }
            }
    }
    
    
    func selectCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageView.alpha = 0.5
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    func updateBottomButton() {
        if self.selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Photos"
        } else {
            bottomButton.title = "Create New Collection"
        }
    }
    
    func updateNoImagesLabel(){
        print("Updating label!!")
        if self.fetchedResultsController.fetchedObjects!.count > 0{
            self.noimages.hidden = true
        }else{
            self.noimages.hidden = false
        }
    }
    
    func centerMap(){
        let center = CLLocationCoordinate2D(latitude: self.pin.coordinate.latitude, longitude: self.pin.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        
        self.mapView.setRegion(region, animated: true)
    }
    
    func alertViewForError(error: NSError) {
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cell.imageView.image = UIImage(named: "downloading")!
        cell.activityView.startAnimating()
        
        if photo.imageName != "" {
            
            let photoURL = photo.flickrURL
            Flicker.sharedInstance().getAndStoreImage(photoURL, completionHandler: { downloaded, error in
                dispatch_async(dispatch_get_main_queue(), {
                    if(downloaded){
                        cell.activityView.stopAnimating()
                        
                        if let image = photo.image(){
                            cell.imageView.image = image
                        }else{
                            cell.imageView.image = UIImage(named: "downloading")!
                        }
                    }else{
                        cell.imageView.image = UIImage(named: "downloading")!
                    }
                })
            })
        }
        
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let objectNumber = self.fetchedResultsController.sections?.count {
            return objectNumber
        }else{
            return 0
        }
    }
    

    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        self.selectCell(cell, atIndexPath: indexPath)
        
        updateBottomButton()
        updateNoImagesLabel()
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            self.insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            self.deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            self.updatedIndexPaths.append(indexPath!)
            break
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        self.collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: {(p:Bool) -> Void in
                self.selectedIndexes = [NSIndexPath]()
                self.updateNoImagesLabel()
                self.updateBottomButton()
        })
    }
    
    func getCollection(){
        
        let resource = "/?method=flickr.photos.search"
        let parameters = ["lat": self.pin.coordinate.latitude, "lon": self.pin.coordinate.longitude, "page": self.pageNumber] 
        
        Flicker.sharedInstance().taskForResource(resource, parameters: parameters as! [String : AnyObject] ){ JSONResult, error  in
            if let error = error {
                self.alertViewForError(error)
            } else {
                
                if let photosDictionaries = JSONResult.valueForKey("photos")!.valueForKey("photo") as? [[String : AnyObject]] {
                    // Parse the array of photos dictionaries
                    let _ = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Void in
                        
                        let photoURL = Flicker.sharedInstance().buildUrlFromDictionary(dictionary)
                        let fileName = NSURL(fileURLWithPath: photoURL).lastPathComponent
                        _ = Photo(imageName: fileName!,flickrURL: photoURL , pin: self.pin, context: self.sharedContext)
                        CoreDataStackManager.sharedInstance().saveContext()

                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView.reloadData()
                        self.updateBottomButton()
                        self.updateNoImagesLabel()
                    }
                    
                    
                }
            }
        }
    }
    
    
}