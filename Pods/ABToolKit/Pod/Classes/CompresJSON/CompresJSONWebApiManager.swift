//
//  CompresJSONWebApiManager.swift
//  Pods
//
//  Created by Alex Bechmann on 01/06/2015.
//
//

import Foundation

private let kEncryptComponents = CompresJSON.sharedInstance().settings.encryptUrlComponents
private let kKey = CompresJSON.sharedInstance().settings.encryptionKey
private let kSecretRestApiPrefix = "apih"
private let kRestApiPrefix = "api"

class CompresJSONWebApiManager: WebApiManager {
    
    override func mutableUrl(id: Int) -> String? {
        
        if kEncryptComponents {
            
            var eRestKey = encryptSecretUrlComponent(restKey!)
            var eID = encryptSecretUrlComponent("\(id)")
            
            return validRestUrlSet() ? "\(getBaseUrl())/\(kSecretRestApiPrefix)/\(eRestKey)/\(eID)" : nil
        }
        
        return super.mutableUrl(id)
    }
    
    override func staticUrl() -> String? {
        
        if kEncryptComponents {
            
            var eRestKey = encryptSecretUrlComponent(restKey!)
            return validRestUrlSet() ? "\(getBaseUrl())/\(kSecretRestApiPrefix)/\(eRestKey)" : nil
        }
        
        return super.staticUrl()
    }
    
    private func encryptSecretUrlComponent(str: String) -> String {
        
        return Encryptor.encrypt(str, key: kKey)
    }
}

