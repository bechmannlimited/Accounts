//
//  oDataManager.swift
//  Pods
//
//  Created by Alex Bechmann on 01/06/2015.
//
//

import UIKit

public class oDataQuery: NSObject {
   
    public var top: Int?
    public var skip: Int?
    
    public func getQuery() -> String {
        
        var query = ""
        var queryComponents = Array<String>()
        
        if let t = top {
            
            queryComponents.append("$top=\(t)")
        }
        
        if let s = skip {
            
            queryComponents.append("$skip=\(s)")
        }
        
        var c = 0
        for component in queryComponents {
            
            let prefix: String = c == 0 ? "?" : "&"
            let append = prefix + component
            query = "\(query)\(append)"
            c++
        }
        
        return query.urlEncode()
    }
}
