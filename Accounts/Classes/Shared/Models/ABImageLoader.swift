//
//  ABImageLoader.swift
//  Accounts
//
//  Created by Alex Bechmann on 13/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
 
import Alamofire
import SwiftyUserDefaults

private let kABImageLoaderSharedInstance = ABImageLoader()
private let kImagePrefix = "DEFAULTS_IMAGE_"

class ABImageLoader: NSObject {
   
    var requestTimes = Dictionary<String, NSDate>()
    
    class func sharedLoader() -> ABImageLoader {
        
        return kABImageLoaderSharedInstance
    }
    
    func loadImageFromCacheThenNetwork(imageUrl: String, completion: (image: UIImage) -> ()) {
        
        if let imageData = Defaults["\(kImagePrefix)\(imageUrl)"].data {
            
            completion(image: UIImage(data: imageData)!)
        }
        
        let getRemoteImage: () -> () = {
            
            ImageLoader.sharedLoader().imageForUrl(imageUrl, completionHandler: { (image, url) -> () in
                
                if let image: UIImage = image {
                    
                    Defaults["\(kImagePrefix)\(imageUrl)"] = UIImagePNGRepresentation(image)
                    
                    completion(image: image)
                    self.requestTimes[imageUrl] = NSDate()
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
