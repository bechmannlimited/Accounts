//
//  Settings.swift
//  Accounts
//
//  Created by Alex Bechmann on 11/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

let kCurrencySettingKey = "CurrencyWithInt"
private let kShowTestBotSettingKey = "ShowTestBot"



class Settings: NSObject {
    
//    class func getCurrencyLocaleWithIdentifier() -> (locale: NSLocale, identifier: String) {
//        
//        if !Defaults.hasKey(kCurrencySettingKey) {
//            
//            Defaults[kCurrencySettingKey] = 0
//        }
//        setDefaultValueIfNotExistsForKey(kCurrencySettingKey, value: 0)
//        
//        let currencyIdentifier: String = Defaults[kCurrencySettingKey].string!
//        
//        return (locale: NSLocale(localeIdentifier: kCurrencySettingLocaleDictionary[currencyIdentifier]!), identifier: currencyIdentifier)
//
//    }
    
    class func setLocaleByIdentifier(identifier: String) {
        
        Defaults[kCurrencySettingKey] = identifier
    }
    
    class func setDefaultValueIfNotExistsForKey(key: String, value: AnyObject) {
        
        if !Defaults.hasKey(key) {
            
            Defaults[key] = value
        }
    }
    
    class func defaultCurrencyId() -> NSNumber {
        
        setDefaultValueIfNotExistsForKey(kCurrencySettingKey, value: 0)
        
        let currencyId: NSNumber = NSNumber(integer: Defaults[kCurrencySettingKey].int!)
        
        return currencyId
    }
    
    class func shouldShowTestBot() -> Bool{
        
        if !Defaults.hasKey(kShowTestBotSettingKey) {
            
            return true
        }
        else {
            
            return Defaults[kShowTestBotSettingKey].bool!
        }
    }
    
    class func setShouldShowTestBot(on: Bool) {
        
        Defaults[kShowTestBotSettingKey] = on
    }
    
    class func setDefaultCurrencyId(id: NSNumber) {
        
        Defaults[kCurrencySettingKey] = Int(id)
    }
}
