//
//  ImageLoader.swift
//  Pods
//
//  Created by Alex Bechmann on 02/06/2015.
//
//

import UIKit

private let kImageLoaderSharedInstance = ImageLoader()

public class ImageLoader {
    
    var cache = NSCache()
    
    public class func sharedLoader() -> ImageLoader {
        
        return kImageLoaderSharedInstance
    }
    
    public func imageForUrl(urlString: String, completionHandler:(image: UIImage?, url: String) -> ()) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {()in
            let data: NSData? = self.cache.objectForKey(urlString) as? NSData
            
            if let goodData = data {
                let image = UIImage(data: goodData)
                
                dispatch_async(dispatch_get_main_queue(), {() in
                    completionHandler(image: image, url: urlString)
                })
                
                return
            }
            
            let downloadTask: NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: urlString)!, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                
                if (error != nil) {
                    
                    completionHandler(image: nil, url: urlString)
                    
                    return
                }
                
                if let data = data {
                    
                    let image = UIImage(data: data)
                    self.cache.setObject(data, forKey: urlString)
                    
                    dispatch_async(dispatch_get_main_queue(), {() in
                        completionHandler(image: image, url: urlString)
                    })
                    
                    return
                }
                
            })
            
            downloadTask.resume()
        })
    }
}