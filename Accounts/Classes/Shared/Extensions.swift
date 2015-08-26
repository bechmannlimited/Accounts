//
//  Extensions.swift
//  Accounts
//
//  Created by Alex Bechmann on 15/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit

extension String {
    
    static func emptyIfNull(str: String?) -> String {
        
        return str != nil ? str! : ""
    }
    
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
}

extension NSDate {
    
    func readableFormattedStringForDateRange() -> String {
        
        var rc = self.toString("dd/MM/yyyy HH:mm")
        var dateRange = DateRange(startDate: self, endDate: NSDate())
        var s = dateRange.months == 1 ? "" : "s"
        rc = "\(dateRange.months) month\(s) ago"
        
        if dateRange.months < 1{
            var text = ""
            switch dateRange.days{
            case 0:
                text = "Today"
                break
            case 1:
                text = "Yesterday"
                break
                
            default:
                text = "\(dateRange.days) days ago"
                break
            }
            rc = text
        }
        
        if dateRange.days < 1{
            var s = dateRange.hours == 1 ? "" : "s"
            rc = "\(dateRange.hours) hour\(s) ago"
        }
        
        if dateRange.days < 1 && dateRange.hours < 1 && dateRange.minutes < 60{
            var s = dateRange.minutes == 1 ? "" : "s"
            rc = "\(dateRange.minutes) min\(s) ago"
        }
        
        if dateRange.days < 1 && dateRange.hours < 1 && dateRange.minutes == 0{
            rc = "Just now"
        }
        
        return rc
    }
}

extension UILabel {
    
    func changeFontWithExistingSize(fontName: String) {
        
        var size: CGFloat = 15
        
        if let previousFontSize = self.font?.pointSize {
            
            size = previousFontSize
        }
        
        self.font = UIFont(name: fontName, size: size)
    }
}

extension UITextField {
    
    func changeFontWithExistingSize(fontName: String) {
        
        var size: CGFloat = 15
        
        if let previousFontSize = self.font?.pointSize {
            
            size = previousFontSize
        }
        
        self.font = UIFont(name: fontName, size: size)
    }
}

extension UIView {
    
    func screenShot() -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawViewHierarchyInRect(bounds, afterScreenUpdates: true)
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension Double {
    
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}


