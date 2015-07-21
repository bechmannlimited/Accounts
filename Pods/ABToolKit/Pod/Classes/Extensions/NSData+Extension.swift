//
//  NSData+Extension.swift
//  CompresJSON
//
//  Created by Alex Bechmann on 10/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

public extension NSData {
 
    public func toString() -> String{
        
        return String(NSString(data: self, encoding: NSUTF8StringEncoding)!)
    }
    
    public func base64String() -> String {
        
        return String(self.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros))
    }
}
