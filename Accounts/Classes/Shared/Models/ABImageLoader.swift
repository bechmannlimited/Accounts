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

class ABImageLoader: NSObject {
   
    class func loadImageFromCacheThenNetwork(imageUrl: String, completion: (image: UIImage) -> ()) {
        
        var didReceiveRemoteImage = false
        
        let cache = Cache<UIImage>(name: "imageCache")
        
        if let image = cache[imageUrl] {
            
            completion(image: image)
        }
        
        ImageLoader.sharedLoader().imageForUrl(imageUrl, completionHandler: { (image, url) -> () in
            
            if let image: UIImage = image {
                
                cache[imageUrl] = image
                completion(image: image)
                didReceiveRemoteImage = true
            }
        })
    }
}
