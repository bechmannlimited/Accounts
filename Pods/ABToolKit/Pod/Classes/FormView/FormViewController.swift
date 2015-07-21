//
//  FormViewController.swift
//  topik-ios
//
//  Created by Alex Bechmann on 31/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit

private let kTextFieldCellIdenfitier = "TextFieldCell"
private let kButtonCellIdentifier = "ButtonCell"


@objc public protocol FormViewDelegate {
    
    func formViewElements() -> Array<Array<FormViewConfiguration>>
    optional func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell
    
    optional func formViewTextFieldEditingChanged(identifier: String, text: String)
    optional func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double)
    optional func formViewDateChanged(identifier: String, date: NSDate)
    optional func formViewButtonTapped(identifier: String)
    optional func formViewDidSelectRow(identifier: String)
    optional func formViewElementDidChange(identifier: String, value: AnyObject?)
    
    optional func formViewElementIsEditable(identifier: String) -> Bool
}

public class FormViewController: BaseViewController {
    
    public var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    public var data: Array<Array<FormViewConfiguration>> = []
    var selectedIndexPath: NSIndexPath?
    public var formViewDelegate: FormViewDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        formViewDelegate = self
        
        shouldAdjustTableViewInsetsForKeyboard = true
        setupTableView(tableView, delegate: self, dataSource: self)
        reloadForm()
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
}

extension FormViewController: UITableViewDelegate, UITableViewDataSource {
    
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
    
        let config:FormViewConfiguration = data[indexPath.section][indexPath.row]
        
        if config.formCellType == FormCellType.TextField || config.formCellType == FormCellType.TextFieldCurrency || config.formCellType == FormCellType.DatePicker {
            
            let cell = FormViewTextFieldCell()
            
            cell.formViewDelegate = formViewDelegate
            cell.config = config
            cell.label.text = config.labelText
            
            if config.formCellType == FormCellType.TextField || config.formCellType == FormCellType.TextFieldCurrency {

                cell.textField.text = config.value as! String
                
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
        else if config.formCellType == FormCellType.None {
            
            if let c = formViewDelegate?.formViewManuallySetCell?(tableView, cellForRowAtIndexPath: indexPath, identifier: config.identifier) {
                
                return c
            }
        }
        
        return UITableViewCell()
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let config:FormViewConfiguration = data[indexPath.section][indexPath.row]
        
        selectedIndexPath = selectedIndexPath != indexPath ? indexPath : nil
        
        if config.formCellType == FormCellType.None {
            
            formViewDelegate?.formViewDidSelectRow?(config.identifier)
        }
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? FormViewTextFieldCell {
            
            cell.textField.becomeFirstResponder()
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

extension FormViewController: FormViewDelegate {
    
    public func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        return [[]]
    }

    public func formViewElementIsEditable(identifier: String) -> Bool {
    
        return true
    }
}
