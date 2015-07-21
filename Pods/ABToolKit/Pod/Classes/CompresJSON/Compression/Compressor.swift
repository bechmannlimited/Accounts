//
//  Compressor.swift
//  CompresJSON
//
//  Created by Alex Bechmann on 09/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

private let kAnalyzer = JavaScriptAnalyzer.sharedInstance()
private let kScriptPath = "encryptor_compressor"

class Compressor: NSObject {
   
    class func compress(str: String) -> String {
        
        kAnalyzer.loadScript(kScriptPath)
        return kAnalyzer.executeJavaScriptFunction("Compress", args: [str]).toString()
    }
    
    class func decompress(str: String) -> String {
        
        kAnalyzer.loadScript(kScriptPath)
        return kAnalyzer.executeJavaScriptFunction("Decompress", args: [str]).toString()
        
//        kAnalyzer.loadScript("jsxcompressor.min") // GZIP for decompress
//        return kAnalyzer.executeJavaScriptFunction("JXG.decompress", args: [str]).toString()
    }
    
}
