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
import Bolts

private let kDisplayNameIndexPath = NSIndexPath(forRow: 2, inSection: 0)
private let kPasswordIndexPath = NSIndexPath(forRow: 0, inSection: 1)
private let kVerifyPasswordIndexPath = NSIndexPath(forRow: 1, inSection: 1)

class SaveUserViewController: ACFormViewController {
    
    var user = User.object()
    var isLoading = false
    
    override func viewDidLoad() {
        
        user.username = User.currentUser()?.username
        user.email = User.currentUser()?.email
        user.displayName = User.currentUser()?.displayName
        
        title = "Edit profile"
        
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
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save")
        
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        
        navigationItem.rightBarButtonItem?.enabled = user.modelIsValid() && !isLoading
    }
    
    func save() {

        isLoading = true
        showOrHideRegisterButton()
        
        User.currentUser()?.username = user.username
        User.currentUser()?.email = user.email
        User.currentUser()?.displayName = user.displayName
        User.currentUser()?.password = user.password
        
        User.currentUser()?.saveInBackgroundWithBlock({ (success, error) -> Void in
            
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
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        User.currentUser()?.fetchIfNeeded()
    }
}

extension SaveUserViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        var sections = Array<Array<FormViewConfiguration>>()
        
        if user.facebookId != nil {
            
            sections.append([
                FormViewConfiguration.textField("Display name", value: String.emptyIfNull(user.displayName), identifier: "DisplayName")
            ])
        }
        else{
            
            sections.append([
                FormViewConfiguration.textField("Username", value: String.emptyIfNull(user.username) , identifier: "Username"),
                FormViewConfiguration.textField("Email", value: String.emptyIfNull(user.email), identifier: "Email"),
                FormViewConfiguration.textField("Display name", value: String.emptyIfNull(user.displayName), identifier: "DisplayName")
            ])
            sections.append([
                
                FormViewConfiguration.textField("Password", value: String.emptyIfNull(user.password), identifier: "Password"),
                FormViewConfiguration.textField("Verify password", value: String.emptyIfNull(user.password), identifier: "PasswordForVerification")
            ])
        }
        
        
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
            
        case "DisplayName":
            user.displayName = text
            break
            
        case "PasswordForVerification":
            user.passwordForVerification = text
            break
            
        default: break;
        }
    }
}

extension SaveUserViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! FormViewTextFieldCell
        
        if indexPath == kPasswordIndexPath || indexPath == kVerifyPasswordIndexPath {
            
            cell.textField.secureTextEntry = true
        }
        
        if indexPath != kDisplayNameIndexPath {
            
            cell.textField.autocapitalizationType = UITextAutocapitalizationType.None
        }

        return cell
    }
}