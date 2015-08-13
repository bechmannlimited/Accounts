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
