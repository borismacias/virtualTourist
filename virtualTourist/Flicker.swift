//
//  Flicker.swift
//  virtualTourist
//
//  Created by Boris Alexis Gonzalez Macias on 10/29/15.
//  Copyright © 2015 PropiedadFacil. All rights reserved.
//


import Foundation

class Flicker : NSObject {
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    
    // MARK: - All purpose task method for data
    
    func taskForResource(resource: String, parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
        
        var mutableParameters = parameters
        let mutableResource = resource
        
        // Add in the API Key
        mutableParameters["api_key"] = "b1476076a491e3cfa3e57435e451f4a6"
        mutableParameters["format"] = "json"
        mutableParameters["nojsoncallback"] = 1
        mutableParameters["radius"] = 5
        mutableParameters["per_page"] = 9
        
        let urlString = "https://api.flickr.com/services/rest" + mutableResource + Flicker.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(result: nil, error: error)
            } else {
                Flicker.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        
        task.resume()
        
        return task
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImageWithSize(url: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: url)!
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()

        return task
    }
    
    func getAndStoreImage(url: String, completionHandler: (downloaded: DarwinBoolean, error: NSError?) ->  Void) -> Void{
        print("Getting and storing!!")
        self.taskForImageWithSize(url, completionHandler: { imageData,error in
            if let result = imageData {
                
                let fileName = NSURL(fileURLWithPath: url).lastPathComponent
                let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                let fileURL = NSURL.fileURLWithPathComponents([dirPath, fileName!])
                
                NSFileManager.defaultManager().createFileAtPath(fileURL!.path!, contents: result, attributes: nil)
                
                completionHandler(downloaded: true, error: nil)
            
            }
        })
        
    }
    
    func buildUrlFromDictionary( dictionary: [String:AnyObject] )-> String{
        return "https://farm\(dictionary["farm"]!).staticflickr.com/\(dictionary["server"]!)/\(dictionary["id"]!)_\(dictionary["secret"]!).jpg"
    }
    
    
    // Parsing the JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {

            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    // URL Encoding a dictionary into a parameter string
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "&" : "") + urlVars.joinWithSeparator("&")
    }
    
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> Flicker {
        
        struct Singleton {
            static var sharedInstance = Flicker()
        }
        
        return Singleton.sharedInstance
    }
    
}
