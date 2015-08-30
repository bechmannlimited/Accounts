//
//  Task.swift
//  Accounts
//
//  Created by Alex Bechmann on 22/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

private let kSharedTasker = Task().setup()

class Task: NSObject {
   
    var operationQueue = NSOperationQueue.new()
    var operations = Dictionary<String, NSOperation>()
    
    class func sharedTasker() -> Task {
        
        return kSharedTasker
    }
    
    private func setup() -> Task {
        
        operationQueue.qualityOfService = .Background
        return self
    }
    
    func cancelAllTasks() {
        
        operationQueue.cancelAllOperations()
    }
    
    func cancelTaskForIdentifier(identifier: String) {
        
        if let operation = operations[identifier] {
            
            operation.cancel()
        }
    }
    
    func executeTaskInBackground(task: () -> (), completion: () -> ()) {
        
        executeTaskInBackgroundWithIdentifier(nil, task: task, completion: completion)
    }
    
    func executeTaskInBackgroundWithIdentifier(identifier: String?, task: () -> (), completion: () -> ()) {
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            task()
            
            dispatch_async(dispatch_get_main_queue()) {
                
                completion()
            }
        }
        
//        let operation: NSOperation = NSBlockOperation { () -> Void in
//            
//            task()
//            println("#1")
//            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
//                
//                println("#2")
//                completion()
//            })
//        }
//        //backgroundOperation.queuePriority = .Low
//        //operation.qualityOfService = .Background
//        
//        if let name = identifier {
//            
//            operation.name = identifier
//            operations[name] = operation
//        }
//        
////        operation.completionBlock = {
////            
////            println("done")
////            completion()
////        }
//        
//        operation.addDependency(NSBlockOperation(block: task))
//        operationQueue.addOperation(operation)
    }
}
