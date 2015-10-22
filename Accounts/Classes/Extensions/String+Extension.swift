//
//  String+Extension.swift
//  objectmapperTest
//
//  Created by Alex Bechmann on 26/04/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

public extension String {
    
    public func characterCount() -> Int {
        
        return self.utf16.count
    }
    
    public func length() -> Int {
        
        return self.utf16.count
    }
    
    public func contains(find: String) -> Bool {
        
        if let _ = self.rangeOfString(find) {
            return true
        }
        return false
    }
    
    public func replaceString(string:String, withString:String) -> String {
        
        return self.stringByReplacingOccurrencesOfString(string, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    public func NSDataFromBase64String() -> NSData {
        
        return NSData(base64EncodedString: self, options: NSDataBase64DecodingOptions())!
    }
    
    public func urlEncode() -> String {
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
    }
    
    public func urlEncodeUrlComponent() -> String {
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
    }
    
    public func base64Encode() -> String {
        
        return self.toData().base64String()
    }
    
    public func base64Decode() -> String {
        
        return NSDataFromBase64String().toString()
    }
    
    public func toData() -> NSData {
        
        return (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    public func toDate(format: String) -> NSDate {
        
        return NSDate.dateFromString(self, format: format)
    }
    
    // MARK: - get characters
    
    public subscript (i: Int) -> Character {
        
        return self.characters[self.characters.startIndex.advancedBy(i)]
    }
//
    public subscript (i: Int) -> String {
        
        return String(self[i])
    }
//
//    public subscript (r: Range<Int>) -> String {
//        
//        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
//    }
    
    // MARK - substring
    
    public func removeLastCharacter() -> String {
        
        return self.substringToIndex(self.endIndex.predecessor())
    }
}