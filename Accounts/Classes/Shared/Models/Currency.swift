//
//  Currency.swift
//  Accounts
//
//  Created by Alex Bechmann on 21/11/2015.
//  Copyright © 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import SwiftyJSON

enum CurrencyEnum: NSNumber {
    
    case GBP = 0
    case EUR = 1
    case USD = 2
    case DKK = 3
}

private let kCurrencySettingLocaleDictionary: Dictionary<NSNumber, String> = [
    0: "en_GB",
    1: "de_LU",
    2: "en_US",
    3: "da_DK"
]

class Currency: NSObject {
    
    static func CurrencyFromNSNumber(number: NSNumber?) -> CurrencyEnum {
        
        if let number = number {
            
            return CurrencyEnum(rawValue: number)!
        }
        else {
            
            return CurrencyEnum.GBP
        }
    }
    
    static func localeForCurrencyId(id: NSNumber?) -> NSLocale {
        
        if let id = id {
            
            return NSLocale(localeIdentifier: kCurrencySettingLocaleDictionary[id]!)
        }
        else {
            
            return NSLocale(localeIdentifier: kCurrencySettingLocaleDictionary[0]!)
        }
    }
    
    static func descriptionForCurrencyId(id: NSNumber?) -> String {
        
        if let id = id {
            
            return "\(Currency.CurrencyFromNSNumber(id))"
        }
        else {
            
            return "\(Currency.CurrencyFromNSNumber(0))"
        }
    }
    
    static func SymbolForCurrency(currency: CurrencyEnum) -> String {
        
        var rc = ""
        
        switch currency {
            
        case CurrencyEnum.GBP:
            
            rc = "£"
            
            break;
            
        case CurrencyEnum.EUR:
            
            rc = "€"
            
            break;
            
        case CurrencyEnum.USD:
            
            rc = "$"
            
            break;
            
        case CurrencyEnum.DKK:
            
            rc = "kr. "
            
            break;
            
        default:
            
            rc = ""
            
            break;
        }
        
        return rc
    }
    
    static func CurrencyDifferencesFromCloudResponse(response: JSON) -> Dictionary<CurrencyEnum, NSNumber> {
        
        var results = Dictionary<CurrencyEnum, NSNumber>()
        
        for (currencyId, amountJson):(String, JSON) in response {
            
            let currencyNSNumber = NSNumber(float: NSNumberFormatter().numberFromString(currencyId)!.floatValue)
            let currency = Currency.CurrencyFromNSNumber(currencyNSNumber)
            let amount = amountJson.numberValue
            
            if amount != 0 {
                
                results[currency] = amount
            }
        }
        
        return results
    }
    
    static func CurrencyDifferencesFromCloudResponseWithStringKey(response: JSON) -> Dictionary<String, NSNumber> {
        
        var results = Dictionary<String, NSNumber>()
        
        for (currencyId, amountJson):(String, JSON) in response {
            
            let currencyKey = JSON(currencyId).stringValue
            let amount = amountJson.numberValue
            
            if amount != 0 {
                
                results[currencyKey] = amount
            }
        }
        
        return results
    }
}