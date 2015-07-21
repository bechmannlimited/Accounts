//
//  UIColor+Extension.swift
//  Pods
//
//  Created by Alex Bechmann on 31/05/2015.
//
//

import Foundation

public extension UIColor {
    
    public class func randomColor() -> UIColor {
        
        var randomRed:CGFloat = CGFloat(drand48())
        var randomGreen:CGFloat = CGFloat(drand48())
        var randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    public convenience init(hex: String) {
        
        self.init(hex: hex, alpha: CGFloat(1.0))
    }
    
    public convenience init(hex: String, alpha: CGFloat) {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(advance(cString.startIndex, 1))
        }
        
        if (count(cString) != 6) {
            
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
        }
        else {
            
            var rgbValue:UInt32 = 0
            NSScanner(string: cString).scanHexInt(&rgbValue)
            
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: alpha
            )
        }
    }
}