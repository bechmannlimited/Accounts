//
//  FormViewController.swift
//  topik-ios
//
//  Created by Alex Bechmann on 31/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
 

private let kTextFieldCellIdenfitier = "TextFieldCell"
private let kButtonCellIdentifier = "ButtonCell"

public protocol FormViewDelegate {
    
    func formViewElements() -> Array<Array<FormViewConfiguration>>
    func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell
    
    func formViewTextFieldEditingChanged(identifier: String, text: String)
    func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double)
    func formViewDateChanged(identifier: String, date: NSDate)
    func formViewSwitchChanged(identifier: String, on: Bool)
    func formViewButtonTapped(identifier: String)
    func formViewDidSelectRow(identifier: String)
    func formViewElementDidChange(identifier: String, value: AnyObject?)
    
    func formViewElementIsEditable(identifier: String) -> Bool
    
    func formViewElementWasDeniedEditing(identifier: String)
}

public class FormViewController: BaseViewController, FormViewDelegate {
    
    public var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    public var data: Array<Array<FormViewConfiguration>> = []
    
    var selectedIndexPath: NSIndexPath?
    public var formViewDelegate: FormViewDelegate?
    public var shouldLoadFormOnLoad = true
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        formViewDelegate = self
        
        shouldAdjustTableViewInsetsForKeyboard = true
        setupTableView(tableView, delegate: self, dataSource: self)
        
        if shouldLoadFormOnLoad {
            
            reloadForm()
        }
    }
    
    public func reloadForm() {
        
        if let elements = formViewDelegate?.formViewElements() {
            
            data = elements
        }
        
        tableView.reloadData()
    }
    
    override public func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        tableView.registerClass(FormViewTextFieldCell.self, forCellReuseIdentifier: kTextFieldCellIdenfitier)
        tableView.registerClass(FormViewButtonCell.self, forCellReuseIdentifier: kButtonCellIdentifier)
        tableView.allowsSelectionDuringEditing = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    
    public func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        return [[]]
    }
    
    public func formViewElementIsEditable(identifier: String) -> Bool {
        
        return true
    }
    
    public func formViewButtonTapped(identifier: String) {
        
    }
    
    public func formViewDateChanged(identifier: String, date: NSDate) {
        
    }
    
    public func formViewDidSelectRow(identifier: String) {
        
    }
    
    public func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
    }
    
    public func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        return UITableViewCell()
    }
    
    public func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double) {
        
    }
    
    public func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
    }
    
    public func formViewSwitchChanged(identifier: String, on: Bool) {
        
    }
    
    public func formViewElementWasDeniedEditing(identifier: String) {
        
        
    }
}

extension FormViewController: UITableViewDataSource {
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let configuration:FormViewConfiguration = data[indexPath.section][indexPath.row]
        
        if configuration.formCellType == FormCellType.DatePicker {
            
            if let path = selectedIndexPath {
                
                if indexPath == path {
                    
                    return 100
                }
            }
        }
        
        return 44
    }
    
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return data.count
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data[section].count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        data = formViewDelegate!.formViewElements()
        let config:FormViewConfiguration = data[indexPath.section][indexPath.row]
        
        if config.formCellType == FormCellType.TextField || config.formCellType == FormCellType.TextFieldCurrency || config.formCellType == FormCellType.DatePicker {
            
            let cell = FormViewTextFieldCell()
            
            cell.formViewDelegate = formViewDelegate
            cell.config = config
            cell.label.text = config.labelText
            
            if config.formCellType == FormCellType.TextField || config.formCellType == FormCellType.TextFieldCurrency {

                cell.textField.text = config.value as! String!
                
                return cell
            }
            else if config.formCellType == FormCellType.DatePicker {
            
                cell.textField.text = (config.value as! NSDate).toString(config.format)
                
                return cell
            }
        }
        else if config.formCellType == FormCellType.Button {
            
            let cell = FormViewButtonCell()
            
            cell.formViewDelegate = formViewDelegate
            cell.config = config
            
            return cell
        }
        else if config.formCellType == FormCellType.Switch {
            
            let cell = FormViewSwitchCell()
            
            cell.formViewDelegate = formViewDelegate
            cell.config = config
            
            return cell
        }
        else if config.formCellType == FormCellType.None {
            
            if let c = formViewDelegate?.formViewManuallySetCell(tableView, cellForRowAtIndexPath: indexPath, identifier: config.identifier) {
                
                return c
            }
        }
        
        return UITableViewCell()
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        data = formViewDelegate!.formViewElements() // needed?
        let config:FormViewConfiguration = data[indexPath.section][indexPath.row]
        
        selectedIndexPath = selectedIndexPath != indexPath ? indexPath : nil
        
        if (formViewDelegate?.formViewElementIsEditable(config.identifier) != nil ? formViewDelegate!.formViewElementIsEditable(config.identifier) : false) {
            
            if config.formCellType == FormCellType.None {
                
                formViewDelegate?.formViewDidSelectRow(config.identifier)
            }
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? FormViewTextFieldCell {
                
                cell.textField.becomeFirstResponder()
            }
            else if let cell = tableView.cellForRowAtIndexPath(indexPath) as? FormViewSwitchCell {
                
                cell.toggleSwitch()
            }
            
        }
        else {
            
            formViewDelegate?.formViewElementWasDeniedEditing(config.identifier)
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    public func indexPathForFormViewCellIdentifier(identifier: String) -> NSIndexPath? {
        
        var sectionIndex = 0
        
        for section in data {
            
            var configIndex = 0
            
            for config in section {
                
                if config.identifier == identifier {
                    
                    return NSIndexPath(forRow: configIndex, inSection: sectionIndex)
                }
                
                configIndex++
            }
            
            sectionIndex++
        }
        
        return nil
    }
}

