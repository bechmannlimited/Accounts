//
//  WebApiUrlManager.swift
//  objectmapperTest
//
//  Created by Alex Bechmann on 29/04/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

let kWebApiDefaultsSharedInstance = WebApiDefaults()


public class WebApiDefaults: NSObject {
 
    public var baseUrl: String?
    
    public class func sharedInstance() -> WebApiDefaults {
        
        return kWebApiDefaultsSharedInstance
    }
}
