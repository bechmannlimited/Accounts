//
//  Settings.swift
//  Accounts
//
//  Created by Alex Bechmann on 11/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

let kCurrencySettingKey = "Currency"

private let kCurrencySettingLocaleDictionary: Dictionary<String, String> = [
    "GBP": "en_GB",
    "DKK": "da_DK"
]

class Settings: NSObject {
    
    class func getCurrencyLocaleWithIdentifier() -> (locale: NSLocale, identifier: String) {
        
        if !Defaults.hasKey(kCurrencySettingKey) {
            
            Defaults[kCurrencySettingKey] = "GBP"
        }
        setDefaultValueIfNotExistsForKey(kCurrencySettingKey, value: "GBP")
        
        let currencyIdentifier: String = Defaults[kCurrencySettingKey].string!
        
        return (locale: NSLocale(localeIdentifier: kCurrencySettingLocaleDictionary[currencyIdentifier]!), identifier: currencyIdentifier)

    }
    
    class func setLocaleByIdentifier(identifier: String) {
        
        Defaults[kCurrencySettingKey] = identifier
    }
    
    class func setDefaultValueIfNotExistsForKey(key: String, value: AnyObject) {
        
        if !Defaults.hasKey(key) {
            
            Defaults[key] = value
        }
    }
}
