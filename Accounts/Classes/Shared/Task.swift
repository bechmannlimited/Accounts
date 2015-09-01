//
//  Task.swift
//  Accounts
//
//  Created by Alex Bechmann on 22/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

private let kSharedTasker = Task()

class Task: NSObject {
   
    var operationBlocks = Dictionary<String, NSBlockOperation>()
    
    class func sharedTasker() -> Task {
        
        return kSharedTasker
    }
    
    func cancelAllTasks() {
        
        for queue in operationBlocks {
            
            queue.1.cancel()
        }
    }
    
    func cancelTaskForIdentifier(identifier: String) {
        
        if let block = operationBlocks[identifier] {

            block.cancel()
        }
    }
    
    func executeTaskInBackground(task: () -> (), completion: (() -> ())?) {
        
        executeTaskInBackgroundWithIdentifier(nil, task: task, completion: completion)
    }
    
    func executeTaskInBackgroundWithIdentifier(identifier: String?, task: () -> (), completion: (() -> ())?) {
        
        var cancelTimer: NSTimer?
        
        var backgroundQueue = NSOperationQueue()
        
        var block = NSBlockOperation()
        
        if let identifier = identifier {
            
            operationBlocks[identifier] = block
        }
        
        block.addExecutionBlock { () -> Void in
         
            var hasFiredCompletionHandler = false
            
            task()
            
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                
                if !block.cancelled {
                    
                    hasFiredCompletionHandler = true
                    completion?()
                }
            }
            
            while !hasFiredCompletionHandler {
                
                if block.cancelled {
                    
                    return
                }
                
                sleep(1 / 2)
            }
        }
        
        backgroundQueue.addOperation(block)
    }
}
