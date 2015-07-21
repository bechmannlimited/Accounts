//
//  LoginViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import Parse

class LoginViewController: ACFormViewController {

    var user = User()
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        title = "Login"
        
        showOrHideLoginButton()
    }
    
    override func setupView() {
        super.setupView()
        
        view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    func login() {
        
        isLoading = true
        showOrHideLoginButton()
        
        if user.username?.length() > 0 && user.password?.length() > 0 {
            
            User.logInWithUsernameInBackground(user.username!, password: user.password!, block: { (user, error) -> Void in
                
                if let error = error {
                    
                    UIAlertView(title: "Login failed!", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
                }
                else {
                    
                    var v = UIStoryboard.initialViewControllerFromStoryboardNamed("Main")
                    self.presentViewController(v, animated: true, completion: nil)
                }
                
                self.isLoading = false
                self.showOrHideLoginButton()
            })
        }
        else {
            
            UIAlertView(title: "Login failed!", message: "Username, password and email are required fields.", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    func showOrHideLoginButton() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .Plain, target: self, action: "login")
        navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        
        navigationItem.rightBarButtonItem?.enabled = user.modelIsValidForLogin() && !isLoading
    }
}


extension LoginViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        var sections = Array<Array<FormViewConfiguration>>()
        sections.append([
            FormViewConfiguration.textField("Username", value: "", identifier: "Username"),
            FormViewConfiguration.textField("Password", value: "", identifier: "Password")
        ])
        return sections
    }
    
    func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        switch identifier {
            
        case "Username":
        user.username = text
        break
            
        case "Password":
        user.password = text
        break;
            
        default: break;
        }
    }
    
    func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        showOrHideLoginButton()
    }
}

extension LoginViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! FormViewTextFieldCell
        
        if indexPath.row == 1 {
            
            cell.textField.secureTextEntry = true
        }
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationType.None
        
        cell.label.textColor = UIColor.blackColor()
        cell.textField.textColor = UIColor.lightGrayColor()
        
        return cell
    }
}