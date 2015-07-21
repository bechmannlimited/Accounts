//
//  UIViewController+Extension.swift
//  objectmapperTest
//
//  Created by Alex Bechmann on 28/04/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

public extension UIViewController {
    
    class func topMostController() -> UIViewController {
        
        var topController = UIApplication.sharedApplication().keyWindow!.rootViewController
        
        while ((topController!.presentedViewController) != nil) {
            
            topController = topController!.presentedViewController;
        }
        
        return topController!
    }
}