//
//  AccountColor.swift
//  Accounts
//
//  Created by Alex Bechmann on 14/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class AccountColor: NSObject {
    
    class func positiveColor() -> UIColor {
        
        return greenColor() // UIColor(hex: "53B01E")
    }
    
    class func negativeColor() -> UIColor {
        
        return UIColor(hex: "D67160") //C75B4A
    }
    
    class func blueColor() -> UIColor {
        
        return UIColor(hex: "00AEE5")
    }
    
    class func greenColor() -> UIColor {
        
        return UIColor(hex: "00BF6A")
    }
}
