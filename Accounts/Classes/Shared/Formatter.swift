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
   
    class func formatCurrencyAsString(currency: CurrencyEnum, value: Double) -> String {
        
        var rc = ""
        
        //let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
        
        switch currency {
            
        case CurrencyEnum.GBP:
            
            rc = "£\(value.toStringWithDecimalPlaces(2))"
            
            break;
            
        case CurrencyEnum.EUR:
            
            rc = "€\(value.toStringWithDecimalPlaces(2))"
            
            break;
            
        case CurrencyEnum.USD:
            
            rc = "$\(value.toStringWithDecimalPlaces(2))"
            
            break;
            
        case CurrencyEnum.DKK:
            
            rc = "kr. \(value.toStringWithDecimalPlaces(2))"
            
            break;
            
        default:break;
        }
        
        return rc
    }
    
}
