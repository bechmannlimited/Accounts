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

class ABImageLoader: NSObject {
   
    class func loadImageFromCacheThenNetwork(imageURL: String, completion: (image: UIImage) -> ()) {
        
        //var image: UIImage?
        
        let imageCache = NSCache()
        
        if let image = imageCache.objectForKey(imageURL) as? UIImage {
            println(image)
            completion(image: image)
        }
        
        let request = Alamofire.request(.GET, imageURL).validate(contentType: ["image/*"]).response() {
            (request, response, data , error) in
            
            if error == nil {
                
                if let data = data as? NSData {
                    
                    let image: UIImage = UIImage(data: data, scale: 1.0)!
                    println(image)
                    
                    imageCache.setObject(image, forKey: request.URLString)
                    
                    completion(image: image)
                }
                
            } else {
                /*
                If the cell went off-screen before the image was downloaded, we cancel it and
                an NSURLErrorDomain (-999: cancelled) is returned. This is a normal behavior.
                */
            }
        }
    }
    
}
