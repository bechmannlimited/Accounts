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
    
//    private func setup() -> Task {
//        
//        operationQueue.qualityOfService = .Background
//        return self
//    }
    
    func cancelAllTasks() {
        
        for queue in operationBlocks {
            
            queue.1.cancel()
        }
    }
    
    func cancelTaskForIdentifier(identifier: String) {
        
        if let block = operationBlocks[identifier] {
            
            println("cancelling: \(identifier))")
            block.cancel()
            println("from inside canceltaskforidentifier:  cancelled \(block.cancelled)")
        }
    }
    
    func executeTaskInBackground(task: () -> (), completion: (() -> ())?) {
        
        executeTaskInBackgroundWithIdentifier(nil, task: task, completion: completion)
    }
    
    func executeTaskInBackgroundWithIdentifier(identifier: String?, task: () -> (), completion: (() -> ())?) {
        
//        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//        
//        dispatch_async(dispatch_get_global_queue(priority, 0)) {
//            
//            task()
//            
//            dispatch_async(dispatch_get_main_queue()) {
//                
//                completion()
//            }
//        }
        
        var cancelTimer: NSTimer?
        
        var backgroundQueue = NSOperationQueue()
        
        var block = NSBlockOperation()
        
        if let identifier = identifier {
            
            println("starting: \(identifier))")
            operationBlocks[identifier] = block
        }
        
        block.addExecutionBlock { () -> Void in
         
            var hasFiredCompletionHandler = false
            
            task()
            
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                
                if !block.cancelled {
                    println("executing closure")
                    hasFiredCompletionHandler = true
                    completion?()
                }
            }
            
            while !hasFiredCompletionHandler {
                
                println("checking \(NSDate()) - cancelled: \(block.cancelled)")
                if block.cancelled {
                    
                    println("returning from while loop")
                    return
                }
                
                sleep(1 / 2)
            }
        }
        
        backgroundQueue.addOperation(block)
        
        
        
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
