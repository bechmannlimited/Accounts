//
//  RegisterViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 20/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
 
import SwiftyJSON
import Parse
import Bolts
import SwiftOverlays

private let kDisplayNameIndexPath = NSIndexPath(forRow: 2, inSection: 0)
private let kPasswordIndexPath = NSIndexPath(forRow: 0, inSection: 1)
private let kVerifyPasswordIndexPath = NSIndexPath(forRow: 1, inSection: 1)

protocol SaveUserDelegate {
    
    func didSaveUser()
}

class SaveUserViewController: ACFormViewController {
    
    var delegate: SaveUserDelegate?
    var userInfo = Dictionary<String, AnyObject>()
    var originalUserInfo = Dictionary<String, AnyObject>()
    var isLoading = false
    var didSave = false
    
    override func viewDidLoad() {
        
        //userInfo["username"] = String.emptyIfNull(User.currentUser()!.username)
        userInfo["email"] = String.emptyIfNull(User.currentUser()!.email)
        userInfo["displayName"] = String.emptyIfNull(User.currentUser()!.displayName)
        //userInfo["password"] = ""
        //userInfo["passwordForVerification"] = ""
        
        for item in userInfo {
            
            originalUserInfo[item.0] = item.1
        }
        
        title = "Edit profile"
        
        showOrHideRegisterButton()
        
        super.viewDidLoad()
    }
    
    func showOrHideRegisterButton() {
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save")
        
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        
        navigationItem.rightBarButtonItem?.enabled = modelIsValid() && !isLoading
    }
    
    func modelIsValid() -> Bool {
        
        //let username = userInfo["username"] as! String
        //let password = userInfo["password"] as! String
        //let passwordForVerification = userInfo["passwordForVerification"] as! String
        //let email = userInfo["email"] as! String

        let valid = (userInfo["displayName"] as! String).characterCount() <= 30
        
        if let id = User.currentUser()?.facebookId {
            
            return id.isEmpty == false && valid
        }
        
        return valid
        //return username.length() > 0 && password.length() > 0 && email.length() > 0 && password == passwordForVerification
    }
    
    func save() {

        isLoading = true
        showOrHideRegisterButton()
        
        for item in self.userInfo {
            
            User.currentUser()?[item.0] = item.1
        }
        
        updateUIForSaving()
        
        User.currentUser()?.saveInBackgroundWithBlock({ (success, error) -> Void in

            if let error = error?.localizedDescription {
                
                UIAlertView(title: "Error", message: error, delegate: nil, cancelButtonTitle: "OK").show()
                
                for item in self.originalUserInfo {
                    
                    User.currentUser()?[item.0] = item.1
                }
            }
            else {
                
                self.navigationController?.popViewControllerAnimated(true)
                self.didSave = true
                self.delegate?.didSaveUser()
            }
            
            self.isLoading = false
            self.showOrHideRegisterButton()
            self.updateUIForEditing()
        })
    }
    
    func updateUIForSaving(){
        
        view.endEditing(true)
        showSavingOverlay()
        view.userInteractionEnabled = false
        navigationController?.navigationBar.userInteractionEnabled = false
        navigationItem.leftBarButtonItem?.enabled = false
        navigationItem.rightBarButtonItem?.enabled = false
    }
    
    func updateUIForEditing() {
        
        view.userInteractionEnabled = true
        navigationController?.navigationBar.userInteractionEnabled = true
        navigationItem.leftBarButtonItem?.enabled = true
        navigationItem.rightBarButtonItem?.enabled = true
        self.removeLoadingViews()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !didSave {
            
            for item in self.originalUserInfo {
                
                User.currentUser()?[item.0] = item.1
            }
        }
    }
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        var sections = Array<Array<FormViewConfiguration>>()
        
        sections.append([
            FormViewConfiguration.textField("Email", value: (userInfo["email"] as! String), identifier: "email"),
            FormViewConfiguration.textField("Display name", value: (userInfo["displayName"] as! String), identifier: "displayName")
            ])
        
        return sections
    }
    
    override func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        userInfo[identifier] = value
        showOrHideRegisterButton()
    }
}

extension SaveUserViewController {
    
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