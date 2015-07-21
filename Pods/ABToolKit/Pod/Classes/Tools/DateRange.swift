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
        return calendar.components(.CalendarUnitMinute,
            fromDate: startDate, toDate: endDate, options: nil).minute
    }
    public var hours: Int {
        return calendar.components(.CalendarUnitHour,
            fromDate: startDate, toDate: endDate, options: nil).hour
    }
    public var days: Int {
        return calendar.components(.CalendarUnitDay,
            fromDate: startDate, toDate: endDate, options: nil).day
    }
    public var months: Int {
        return calendar.components(.CalendarUnitMonth,
            fromDate: startDate, toDate: endDate, options: nil).month
    }
    public init(startDate:NSDate, endDate:NSDate) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

public func -(lhs:NSDate, rhs:NSDate) -> DateRange {
    return DateRange(startDate: rhs, endDate: lhs)
}