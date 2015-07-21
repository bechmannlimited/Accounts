//
//  RegisterViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 20/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit
import SwiftyJSON
import Parse

class SaveUserViewController: ACFormViewController {
    
    var user = User.object()
    var isLoading = false
    
    override func viewDidLoad() {
        
        if user.objectId == nil {
            
            title = "Register"
        }
        else {
            
            title = "Edit profile"
        }
        
        showOrHideRegisterButton()
        
        
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if view.frame.width >= kTableViewMaxWidth {
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
    }
    
    override func setupView() {
        super.setupView()
        
        view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    func showOrHideRegisterButton() {
        
        let saveButton = user.objectId == nil ? UIBarButtonItem(title: "Register", style: .Plain, target: self, action: "save") : UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save")
        
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        
        navigationItem.rightBarButtonItem?.enabled = user.modelIsValid() && !isLoading
    }
    
    func save() {
        
        if user.objectId != nil {
            
            isLoading = true
            showOrHideRegisterButton()
            
            user.saveInBackgroundWithBlock({ (success, error) -> Void in
                
                if success {
                    
                    self.navigationController?.popViewControllerAnimated(true)
                }
                else if let error = error?.localizedDescription {
                    
                    UIAlertView(title: "Error", message: error, delegate: nil, cancelButtonTitle: "OK").show()
                }
                
                self.isLoading = false
                self.showOrHideRegisterButton()
            })
        }
        else {
            
            isLoading = true
            showOrHideRegisterButton()
            
            user.signUpInBackgroundWithBlock({ (success, error) -> Void in
                
                if success {
                    
                    var v = UIStoryboard.initialViewControllerFromStoryboardNamed("Main")
                    self.presentViewController(v, animated: true, completion: nil)
                }
                else if let error = error?.localizedDescription {
                    
                    UIAlertView(title: "Error", message: error, delegate: nil, cancelButtonTitle: "OK").show()
                }
            })
            
            self.isLoading = false
            self.showOrHideRegisterButton()
        }
    }
}

extension SaveUserViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        var sections = Array<Array<FormViewConfiguration>>()
        sections.append([
            FormViewConfiguration.textField("Username", value: String.emptyIfNull(user.username) , identifier: "Username"),
            FormViewConfiguration.textField("Email", value: String.emptyIfNull(user.email), identifier: "Email"),
            FormViewConfiguration.textField("Password", value: String.emptyIfNull(user.password), identifier: "Password")
        ])
        sections.append([
            FormViewConfiguration.textField("Display name", value: String.emptyIfNull(user.displayName), identifier: "DisplayName")
        ])
        return sections
    }
    
    func formViewElementDidChange(identifier: String, value: AnyObject?) {

        showOrHideRegisterButton()
    }
    
    func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        switch identifier {
            
        case "Username":
            user.username = text
            break
            
        case "Password":
            user.password = text
            break;
            
        case "Email":
            user.email = text
            break
            
        case "displayName":
            user.displayName = text
            break
            
        default: break;
        }
    }
}

extension SaveUserViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! FormViewTextFieldCell
        
        if indexPath.row == 2 {
            
            cell.textField.secureTextEntry = true
        }
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationType.None
        
        return cell
    }
}