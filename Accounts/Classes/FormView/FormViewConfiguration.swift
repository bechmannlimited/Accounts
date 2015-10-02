//
//  FormViewConfiguration.swift
//  Pods
//
//  Created by Alex Bechmann on 09/06/2015.
//
//

import UIKit

public enum FormCellType {
    
    case None
    case DatePicker
    case TextField
    case TextFieldCurrency
    case Button
}

public class FormViewConfiguration {
    
    public var labelText: String = ""
    public var formCellType = FormCellType.TextField
    public var value: AnyObject?
    public var identifier: String = ""
    
    //currency
    public var currencyLocale = NSLocale(localeIdentifier: "en_GB")
    
    //button
    public var buttonTextColor = UIColor.blueColor()
    
    //datepicker
    public var format: String = DateFormat.DateTime.rawValue
    
    private convenience init(labelText: String, formCellType: FormCellType, value: AnyObject?, identifier: String) {
        
        self.init()
        self.labelText = labelText
        self.formCellType = formCellType
        self.value = value
        self.identifier = identifier
    }
    
    public class func datePicker(labelText: String, date: NSDate?, identifier: String, format: String?) -> FormViewConfiguration {
        
        let config = FormViewConfiguration(labelText: labelText, formCellType: FormCellType.DatePicker, value: date, identifier: identifier)
        
        if let f = format {
            
            config.format = f
        }
        
        return config
    }
    
    public class func textField(labelText: String, value: String?, identifier: String) -> FormViewConfiguration {
        
        return FormViewConfiguration(labelText: labelText, formCellType: FormCellType.TextField, value: value, identifier: identifier)
    }
    
    public class func textFieldCurrency(labelText: String, value: String?, identifier: String) -> FormViewConfiguration {
        
        return textFieldCurrency(labelText, value: value, identifier: identifier, locale: nil)
    }
    
    public class func textFieldCurrency(labelText: String, value: String?, identifier: String, locale: NSLocale?) -> FormViewConfiguration {
        
        let config = FormViewConfiguration(labelText: labelText, formCellType: FormCellType.TextFieldCurrency, value: value, identifier: identifier)
        
        if let l = locale {
            
            config.currencyLocale = l
        }
        
        return config
    }
    
    public class func button(buttonText: String, buttonTextColor: UIColor, identifier: String) -> FormViewConfiguration {
        
        let config = FormViewConfiguration(labelText: buttonText, formCellType: FormCellType.Button, value: nil, identifier: identifier)
        config.buttonTextColor = buttonTextColor
        
        return config
    }
    
    public class func normalCell(identifier: String) -> FormViewConfiguration {
        
        return FormViewConfiguration(labelText: "", formCellType: FormCellType.None, value: nil, identifier: identifier)
    }

}
