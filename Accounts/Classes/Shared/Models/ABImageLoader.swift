//
//  ABImageLoader.swift
//  Accounts
//
//  Created by Alex Bechmann on 13/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import Alamofire
import AwesomeCache

private let kABImageLoaderSharedInstance = ABImageLoader()

class ABImageLoader: NSObject {
   
    var requestTimes = Dictionary<String, NSDate>()
    
    class func sharedLoader() -> ABImageLoader {
        
        return kABImageLoaderSharedInstance
    }
    
    func loadImageFromCacheThenNetwork(imageUrl: String, completion: (image: UIImage) -> ()) {
        
        var didReceiveRemoteImage = false
        var didReceiveCachedImage = false
        
        let cache = Cache<UIImage>(name: "imageCache")
        
        if let image = cache[imageUrl] {
            
            completion(image: image)
            didReceiveCachedImage = true
        }
        
        let getRemoteImage: () -> () = {
            
            ImageLoader.sharedLoader().imageForUrl(imageUrl, completionHandler: { (image, url) -> () in
                
                if let image: UIImage = image {
                    
                    cache[imageUrl] = image
                    completion(image: image)
                    didReceiveRemoteImage = true
                    self.requestTimes[imageUrl] = NSDate()
                    println("received remote image \(NSDate()))")
                }
            })
        }
        
        if let timeForRequestWithUrl = requestTimes[imageUrl] {
            
            if (NSDate() - timeForRequestWithUrl).minutes == 15 {
                
                getRemoteImage()
            }
        }
        else {
            
            getRemoteImage()
        }
    }
}
