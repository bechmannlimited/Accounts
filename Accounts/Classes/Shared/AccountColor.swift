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
        
        return darkGreenColor() // UIColor(hex: "53B01E")
    }
    
    class func negativeColor() -> UIColor {
        
        return darkRedColor() //C75B4A
    }
    
    class func blueColor() -> UIColor {
        
        return UIColor(hex: "00AEE5")
    }
    
    class func greenColor() -> UIColor {
        
        return UIColor(hex: "00BF6A") // UIColor(hex: "00BF6A")
    }
    
    class func grayColor() -> UIColor {
        
        return UIColor(hex: "F2F2F2") // UIColor(red: 242 / 255, green: 242 / 255, blue: 235 / 255, alpha: 10)
    }
    
    class func darkRedColor() -> UIColor {
        
        return UIColor(hex: "BF6556")
    }
    
    class func darkGreenColor() -> UIColor {
        
        return UIColor(hex: "448A3E")
    }
    
    class func redColor() -> UIColor {
        
        return UIColor(hex: "D67160")
    }
    
}
