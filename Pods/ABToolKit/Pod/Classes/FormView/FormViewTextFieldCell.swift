//
//  FormViewTextFieldTableViewCell.swift
//  topik-ios
//
//  Created by Alex Bechmann on 31/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

let kPadding: CGFloat = 15

public class FormViewTextFieldCell: FormViewCell {

    public var label = UILabel()
    public var textField = UITextField()
    public var datePicker: UIDatePicker?
    
    override public func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.addSubview(label)
        
        textField.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.addSubview(textField)
        textField.textAlignment = NSTextAlignment.Right
        
        setupLabelConstraints()
        setupTextFieldConstraints()
    
        if config.formCellType == FormCellType.TextField {
            
            textField.addTarget(self, action: "textFieldChanged:", forControlEvents: UIControlEvents.EditingChanged)
        }
        else if config.formCellType == FormCellType.TextFieldCurrency {
            
            textField.keyboardType = UIKeyboardType.DecimalPad
            textField.delegate = self
        }
        else if config.formCellType == FormCellType.DatePicker {

            setupDatePicker()
            textField.inputView = datePicker!
            textField.tintColor = UIColor.clearColor()
        }
        
        textField.userInteractionEnabled = editable
    }
    
    public func textFieldChanged(textField: UITextField) {
        
        formViewDelegate?.formViewTextFieldEditingChanged?(config.identifier, text: textField.text)
        formViewDelegate?.formViewElementDidChange?(config.identifier, value: textField.text)
    }
    
    func setupDatePicker() {
        
        datePicker = UIDatePicker()
        datePicker?.date = config.value as! NSDate
        datePicker?.addTarget(self, action: "datePickerValueDidChange:", forControlEvents: UIControlEvents.ValueChanged)
        datePicker?.backgroundColor = UIColor(red: 246 / 255, green: 246 / 255, blue: 247 / 255, alpha: 1)
        datePicker?.sizeToFit()
    }
    
    func datePickerValueDidChange(datePicker: UIDatePicker) {
        
        textField.text = datePicker.date.toString(config.format)
        formViewDelegate?.formViewDateChanged?(config.identifier, date: datePicker.date)
        formViewDelegate?.formViewElementDidChange?(config.identifier, value: datePicker.date)
    }
    
    func setDateToToday() {
        
        datePicker?.setDate(NSDate(), animated: true)
        datePickerValueDidChange(datePicker!)
    }
    
    
    // MARK: - Constraints
    
    public func setupLabelConstraints() {
        
        label.addTopConstraint(toView: contentView, relation: .Equal, constant: 0)
        label.addLeftConstraint(toView: contentView, relation: .Equal, constant: kPadding)
        label.addBottomConstraint(toView: contentView, relation: .Equal, constant: 0)
        label.addWidthConstraint(relation: .Equal, constant: 160)
    }
    
    public func setupTextFieldConstraints() {
        
        textField.addTopConstraint(toView: contentView, relation: .Equal, constant: 0)
        textField.addLeftConstraint(toView: label, attribute: NSLayoutAttribute.Right, relation: .Equal, constant: 0)
        textField.addRightConstraint(toView: contentView, relation: .Equal, constant: -kPadding)
        textField.addBottomConstraint(toView: contentView, relation: .Equal, constant: 0)
    }
}

extension FormViewTextFieldCell: UITextFieldDelegate {
    
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if config.formCellType == FormCellType.TextFieldCurrency {
            
            // Construct the text that will be in the field if this change is accepted
            var oldText = textField.text as NSString
            var newText = oldText.stringByReplacingCharactersInRange(range, withString: string) as NSString!
            var newTextString = String(newText)
            
            let digits = NSCharacterSet.decimalDigitCharacterSet()
            var digitText = ""
            for c in newTextString.unicodeScalars {
                if digits.longCharacterIsMember(c.value) {
                    digitText.append(c)
                }
            }
            
            let formatter = NSNumberFormatter()
            formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            formatter.locale = config.currencyLocale
            var numberFromField = (NSString(string: digitText).doubleValue)/100
            newText = formatter.stringFromNumber(numberFromField)
            
            textField.text = String(newText)
            
            if config.currencyLocale == NSLocale(localeIdentifier: "da_DK") {
                
                textField.text = textField.text.replaceString("kr", withString: "").removeLastCharacter()
                textField.text = "kr, \(textField.text)"
            }
            
            formViewDelegate?.formViewTextFieldCurrencyEditingChanged?(config.identifier, value: numberFromField)
            formViewDelegate?.formViewElementDidChange?(config.identifier, value: numberFromField)
            
            return false
        }
        
        return true
    }
}
