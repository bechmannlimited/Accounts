//
//  IOSession.swift
//  Accounts
//
//  Created by Alex Bechmann on 13/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

private let kIOSessionSharedInstance = IOSession()

class IOSession: NSObject {
   
    class func sharedSession() -> IOSession {
        
        return kIOSessionSharedInstance
    }
    
    var deletedTransactionIds = [String]()
}
