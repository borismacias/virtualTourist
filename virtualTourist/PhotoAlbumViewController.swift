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

    // MARK: - Indexes used for the collection view
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
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    @IBAction func getNewCollection(sender: AnyObject) {
        
        // MARK: - Bottom button functionality depends if the user has selected some images
        
        if(self.selectedIndexes.count==0){
            self.pageNumber++
            for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
                self.sharedContext.deleteObject(photo)
            }
            self.pin.getCollection(self.pageNumber,completionHandler: {success in
                print("success: \(success)")
            })
        }
        else{
            for index in self.selectedIndexes {
                let photo = self.fetchedResultsController.objectAtIndexPath(index) as! Photo
                self.sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
        }
        selectedIndexes = [NSIndexPath]()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - Resetting page number
        pageNumber = 1
        updateBottomButton()
        // MARK: - Resetting the map
        removePins()
        // MARK: - Adding the selected pin to the map
        self.mapView.addAnnotation(pin)
        centerMap()
        // MARK: - If there are no photos related to the pin, ask for them
        print("objects: \(self.fetchedResultsController.fetchedObjects!.count)")
        if self.fetchedResultsController.fetchedObjects!.count == 0 {
            self.pin.getCollection(self.pageNumber, completionHandler: {success in
                self.updateBottomButton()
                self.updateNoImagesLabel()
            })
            
        }
        
    }
    
    func removePins(){
        // MARK: - Deleting every pin in the map (only one, but since i didint have a way to get it, ill just loop through every pin in the map)
        let annotations = self.mapView.annotations
            for _annotation in annotations {
                if let annotation = _annotation as MKAnnotation?
                {
                    self.mapView.removeAnnotation(annotation)
                }
            }
    }
    
    // MARK: - Convenience methods
    func selectCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        if let index = selectedIndexes.indexOf(indexPath) {
            cell.imageView.alpha = 1.0
            self.selectedIndexes.removeAtIndex(index)
        } else {
            self.selectedIndexes.append(indexPath)
            cell.imageView.alpha = 0.5
        }
    }
    
    func updateBottomButton() {
        if self.selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Photos"
        } else {
            bottomButton.title = "Create New Collection"
        }
    }
    
    func updateNoImagesLabel(){
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
    
    
    
    // MARK: - CollectionView Delegate methods
    
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
            
            if (NSFileManager.defaultManager().fileExistsAtPath(photo.imageURL()))
            {
                cell.imageView.image = photo.image()
                cell.activityView.stopAnimating()
            }
            else
            {
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
        
        self.selectCell(cell, atIndexPath: indexPath)
        
        updateBottomButton()
        updateNoImagesLabel()
    }
    
    // MARK: - More delegate methods
    
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
            
            }, completion: nil)
    }
    
}