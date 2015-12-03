//
//  AppTools.swift
//  Accounts
//
//  Created by Alex Bechmann on 14/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class AppTools: NSObject {
   
    class func iconAssetNamed(file: String) -> UIImage {
        
        return UIImage(named: "Assets/Icons/\(file)")!
    }
    
}

extension NKTouchID {
    
    class func touchIDIsAvailableForIOUApp() -> Bool {
        
        if #available(iOS 9.0, *) {
            
            if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) && NKTouchID.canUseTouchID() {
                
                return true
            }
        }
        
        return false
    }
}
