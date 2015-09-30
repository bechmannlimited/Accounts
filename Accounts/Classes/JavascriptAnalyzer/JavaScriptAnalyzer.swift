////
////  JavaScriptAnalyzer.swift
////  CompresJSON
////
////  Created by Alex Bechmann on 12/05/2015.
////  Copyright (c) 2015 Alex Bechmann. All rights reserved.
////
//
//import UIKit
//import JavaScriptCore
//
//let kJavascriptAnalyzerSharedInstance = JavaScriptAnalyzer()
//
//public class JavaScriptAnalyzer: NSObject {
//   
//    public var context: JSContext?
//    
//    public class func sharedInstance() -> JavaScriptAnalyzer {
//        
//        return kJavascriptAnalyzerSharedInstance
//    }
//    
//    public func loadScript(name: String) {
//        
//        let resource = NSBundle.mainBundle().pathForResource(name, ofType: "txt")!
//        
//        var error: NSError?
//        let script: String?
//        do {
//            script = try String(contentsOfFile: resource, encoding: NSUTF8StringEncoding)
//        } catch let error1 as NSError {
//            error = error1
//            script = nil
//        }
//        
//        context = JSContext()
//        
//        context?.exceptionHandler = { context, exception in
//            print("JS Error: \(exception)")
//        }
//        
//        context?.evaluateScript(script)
//    }
//    
//    public func executeJavaScriptFunction(functionName: String, args:Array<AnyObject>) -> JSValue {
//        
//        let function = context!.objectForKeyedSubscript(functionName)
//        return function.callWithArguments(args)
//        
//    }
//    
//    func loadScriptInternally(name: String) {
//        
//        //var bundlePath = NSBundle.mainBundle().pathForResource("ABToolKitResources", ofType: "bundle")!
//        let bundlePath = NSBundle.mainBundle().pathForResource("ABToolKitResources", ofType: "bundle", inDirectory: nil)!
//        let bundle = NSBundle(path: bundlePath)!
//        
//        //var bundle: NSBundle = NSBundle(identifier: "ABToolkit")!
//        
//        let resource = bundle.pathForResource(name, ofType: "txt")!
//        
//        var error: NSError?
//        let script: String?
//        do {
//            script = try String(contentsOfFile: resource, encoding: NSUTF8StringEncoding)
//        } catch let error1 as NSError {
//            error = error1
//            script = nil
//        }
//        
//        context = JSContext()
//        context?.evaluateScript(script)
//    }
//    
//}
