//
//  NSObjec+Extension.swift
//  Pods
//
//  Created by Alex Bechmann on 01/06/2015.
//
//

import Foundation

public extension NSObject {
    
    public class func getClassName() -> String {
        
        let classString = NSStringFromClass(self)
        let range = classString.rangeOfString(".", options: NSStringCompareOptions.CaseInsensitiveSearch, range: Range<String.Index>(start:classString.startIndex, end: classString.endIndex), locale: nil)
        return classString.substringFromIndex(range!.endIndex)
    }
}
