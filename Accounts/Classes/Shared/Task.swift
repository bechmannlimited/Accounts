//
//  Task.swift
//  Accounts
//
//  Created by Alex Bechmann on 22/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class Task: NSObject {
   
    class func executeTaskInBackground(task: () -> (), completion: () -> ()) {
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            task()
            
            dispatch_async(dispatch_get_main_queue()) {
                
                completion()
            }
        }
    }
    
}
