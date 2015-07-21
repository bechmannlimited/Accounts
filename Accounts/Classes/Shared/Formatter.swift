//
//  Formatter.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class Formatter: NSObject {
   
    class func formatCurrencyAsString(value: Double) -> String {
        
        let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
        
        if currencyIdentifier == "DKK" {
            
            return "kr, \(value.toStringWithDecimalPlaces(2))"
        }
        
        return "£\(value.toStringWithDecimalPlaces(2))"
    }
    
}
