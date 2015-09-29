//
//  String+Extension.swift
//  CompresJSON
//
//  Created by Alex Bechmann on 09/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

public extension String {
    
    //compression
    public func compress() -> String {
        
        return Compressor.compress(self)
    }
    
    public func decompress() -> String {
        
        return Compressor.decompress(self)
    }
    
    //encryption
    public func encrypt(key: String) -> String {
        
        return Encryptor.encrypt(self, key: key)
    }
    
    public func decrypt(key: String) -> String {
        
        return Encryptor.decrypt(self, key: key)
    }
    
}