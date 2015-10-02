//
//  Session.swift
//  Pods
//
//  Created by Alex Bechmann on 01/06/2015.
//
//

import UIKit

private var kSessionSharedInstance = Session()

public class Session: NSObject {
   
    public var domain: String = ""
    
    public class func sharedSession() -> Session {
        
        return kSessionSharedInstance
    }
}
