//
//  DateRange.swift
//  Pods
//
//  Created by Alex Bechmann on 31/05/2015.
//
//

import Foundation

public class DateRange {
    
    let startDate:NSDate
    let endDate:NSDate
    public var calendar = NSCalendar.currentCalendar()
    
    public var minutes: Int {
        return calendar.components(.Minute,
            fromDate: startDate, toDate: endDate, options: []).minute
    }
    public var hours: Int {
        return calendar.components(.Hour,
            fromDate: startDate, toDate: endDate, options: []).hour
    }
    public var days: Int {
        return calendar.components(.Day,
            fromDate: startDate, toDate: endDate, options: []).day
    }
    public var months: Int {
        return calendar.components(.Month,
            fromDate: startDate, toDate: endDate, options: []).month
    }
    public init(startDate:NSDate, endDate:NSDate) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

public func -(lhs:NSDate, rhs:NSDate) -> DateRange {
    return DateRange(startDate: rhs, endDate: lhs)
}