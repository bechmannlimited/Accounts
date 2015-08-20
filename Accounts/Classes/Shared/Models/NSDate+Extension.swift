//
//  NSDate+Extension.swift
//  Accounts
//
//  Created by Alex Bechmann on 19/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import Foundation

extension NSDate: Equatable {}
extension NSDate: Comparable {}

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 == rhs.timeIntervalSince1970
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
}