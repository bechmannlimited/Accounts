//
//  WebApiUrlManager.swift
//  objectmapperTest
//
//  Created by Alex Bechmann on 29/04/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

private let kKey = CompresJSON.sharedInstance().settings.encryptionKey

public class WebApiManager: NSObject {
   
    public var baseUrl: String?
    public var restKey: String?
    
    public func setupUrlsForREST(restKey: String, overrideBase: String?) -> WebApiManager {
        
        baseUrl = overrideBase
        self.restKey = restKey
        
        return self
    }
    
    public func setupUrlsForREST(key: String) -> WebApiManager {
        
        return setupUrlsForREST(key, overrideBase: nil)
    }
    
    func getBaseUrl() -> String{
        
        var domain = ""
        
        if let d = WebApiDefaults.sharedInstance().baseUrl {
            
            domain = d
        }
        
        if let d = baseUrl {
            
            domain = d
        }
        
        return domain
    }
    
    func mutableUrl(id: Int) -> String? {
        
        return validRestUrlSet() ? "\(getBaseUrl())/\(restKey!)/\(id)" : nil
    }
    
    func staticUrl() -> String? {
        
        return validRestUrlSet() ? "\(getBaseUrl())/\(restKey!)" : nil
    }
    
    public func updateUrl(id: Int?) -> String? {
        
        if let id = id {
            
            return mutableUrl(id)
        }
        
        return nil
    }
    
    public func insertUrl() -> String? {
        
        return staticUrl()
    }
    
    public func getUrl(id: Int) -> String? {
        
        return mutableUrl(id)
    }
    
    public func getMultipleUrl() -> String? {
        
        return staticUrl()
    }
    
    public func deleteUrl(id: Int?) -> String? {
        
        if let id = id {
            
            return mutableUrl(id)
        }
        
        return nil
    }
    
    public func validRestUrlSet() -> Bool {
     
        return restKey != nil
    }
}
