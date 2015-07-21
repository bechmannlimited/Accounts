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
