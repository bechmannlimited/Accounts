//
//  Encryptor.swift
//  EncryptionTests3
//
//  Created by Alex Bechmann on 08/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

private let kAnalyzer = JavaScriptAnalyzer.sharedInstance()
private let kScriptPath = "encryptor_compressor"

public class Encryptor: NSObject {
   
    public class func encrypt(str: String, key: String) -> String {
        
        Encryptor.printErrorIfEncryptionKeyIsNotSet()
        
        kAnalyzer.loadScript(kScriptPath)
        let encrypted = kAnalyzer.executeJavaScriptFunction("Encrypt", args: [str, key]).toString()
        
        return encrypted.base64Encode()
    }
    
    public class func decrypt(str: String, key: String) -> String {
        
        Encryptor.printErrorIfEncryptionKeyIsNotSet()
        
        kAnalyzer.loadScript(kScriptPath)
        let decoded = str.base64Decode()
        
        return kAnalyzer.executeJavaScriptFunction("Decrypt", args: [decoded, key]).toString()
    }
    
    public class func printErrorIfEncryptionKeyIsNotSet() {
        
        if CompresJSON.sharedInstance().settings.encryptionKey == "" {
            
            println("Encryption key not set: add to appdelegate: CompresJSON.sharedInstance().settings.encryptionKey = xxxx")
        }
    }
    
}

