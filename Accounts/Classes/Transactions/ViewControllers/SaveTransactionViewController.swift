//
//  SaveTransactionViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 08/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit
import SwiftyUserDefaults

class SaveTransactionViewController: SaveItemViewController {

    var transaction = Transaction()
    var isNew = true
    
    override func viewDidLoad() {

        shouldLoadFormOnLoad = false
        super.viewDidLoad()
        
        if transaction.objectId == nil {

            transaction.fromUser = User.currentUser()
            transaction.transactionDate = NSDate()
            transaction.title = ""
            showOrHideSaveButton()
            reloadForm()
        }

        allowEditing = true // transaction.TransactionID == 0 || transaction.user.UserID == kActiveUser.UserID
        
        if allowEditing && transaction.objectId == nil {
            
            title = "New transfer"
        }
        else if allowEditing && transaction.objectId != nil {
            
            title = "Edit transfer"
        }
        else {
            
            title = "Transfer"
        }
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "askToPopIfChanged")
        
        if transaction.objectId != nil {
            
            updateUIForServerInteraction()
            
            Task.executeTaskInBackground({ () -> () in
                
                self.transaction.fetchIfNeeded()
                self.transaction.toUser?.fetchIfNeeded()
                self.transaction.fromUser?.fetchIfNeeded()
                self.isNew = false
                
            }, completion: { () -> () in
                
                self.updateUIForEditing()
                self.reloadForm()
            })
        }
        
        askToPopMessage = "Going back delete changes to this transaction! Are you sure?"
    }
    
    func save() {

        updateUIForSavingOrDeleting()
        
        transaction.saveInBackgroundWithBlock { (success, error) -> Void in

            if success {

                self.delegate?.transactionDidChange(self.transaction)
                self.self.popAll()
                self.delegate?.itemDidChange()
                
                self.transaction.sendPushNotifications(self.isNew)
            }
            else {
            
                ParseUtilities.showAlertWithErrorIfExists(error)
            }

            self.updateUIForEditing()
        }
    }
    
    override func saveButtonEnabled() -> Bool {
        
        return allowEditing && transaction.modelIsValid() && !isSaving
    }
    
    
}

extension SaveTransactionViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        let locale = Settings.getCurrencyLocaleWithIdentifier().locale
        
        var sections = Array<Array<FormViewConfiguration>>()
        sections.append([
            FormViewConfiguration.textField("Title", value: String.emptyIfNull(transaction.title), identifier: "Title"),
            FormViewConfiguration.textFieldCurrency("Amount", value: Formatter.formatCurrencyAsString(transaction.localeAmount), identifier: "Amount", locale: locale)
        ])
        
        sections.append([
            FormViewConfiguration.normalCell("User"),
            FormViewConfiguration.normalCell("Friend"),
            FormViewConfiguration.datePicker("Transaction date", date: transaction.transactionDate, identifier: "TransactionDate", format: nil)
        ])
        
        if transaction.objectId != nil {
            
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
            ])
        }
        
        return sections
    }
    
    func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
        
        if identifier == "Friend" {
            
            cell.textLabel?.text = "Transfer to"
            if let username = transaction.toUser?.appropriateDisplayName() {
                
                cell.detailTextLabel?.text = "\(username)"
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            }
            else{
                
                cell.detailTextLabel?.text = ""
            }

            return cell
        }
        
        if identifier == "User" {
            
            cell.textLabel?.text = "Transfer from"
            if let username = transaction.fromUser?.appropriateDisplayName() {
                
                cell.detailTextLabel?.text = "\(username)"
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            }
            else{
                
                cell.detailTextLabel?.text = ""
            }
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    func formViewDateChanged(identifier: String, date: NSDate) {
        
        if identifier == "TransactionDate" {
            
            transaction.transactionDate = date
        }
    }
    
    func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        if identifier == "Title" {

            transaction.title = text
        }
    }
    
    func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double) {
        
        if identifier == "Amount" {

            transaction.localeAmount = value
        }
    }
    
    func formViewButtonTapped(identifier: String) {
        
        if identifier == "Delete" {

            UIAlertController.showAlertControllerWithButtonTitle("Delete", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Delete transaction for \(Formatter.formatCurrencyAsString(transaction.localeAmount))?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.updateUIForSavingOrDeleting()
                    
                    self.transaction.deleteInBackgroundWithBlock({ (success, error) -> Void in
                        
                        ParseUtilities.showAlertWithErrorIfExists(error)
                        
                        self.popAll()
                        self.delegate?.itemDidGetDeleted()
                        
                        ParseUtilities.sendPushNotificationsInBackgroundToUsers(self.transaction.pushNotificationTargets(), message: "Transfer: \(self.transaction.title!) was deleted by \(User.currentUser()!.appropriateDisplayName())!", data: [kPushNotificationTypeKey : PushNotificationType.ItemSaved.rawValue])
                    })
                }
            })
        }
    }
    
    func formViewDidSelectRow(identifier: String) {
        
        if identifier == "Friend" {

            let usersToChooseFrom = User.userListExcludingID(transaction.fromUser?.objectId)
            
            let v = SelectUsersViewController(identifier: identifier, user: transaction.toUser, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
            navigationController?.pushViewController(v, animated: true)
        }
        
        if identifier == "User" {
            
            let usersToChooseFrom = User.userListExcludingID(nil)
            
            let v = SelectUsersViewController(identifier: identifier, user: transaction.fromUser, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
            navigationController?.pushViewController(v, animated: true)
        }
    }
    
    override func formViewElementIsEditable(identifier: String) -> Bool {
        
        return allowEditing
    }
    
    func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        showOrHideSaveButton()
        itemDidChange = true
    }
}

extension SaveTransactionViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if let c = cell as? FormViewTextFieldCell {
            
            c.label.textColor = UIColor.blackColor()
            c.textField.textColor = UIColor.lightGrayColor()
        }
        
        return cell
    }
}

extension SaveTransactionViewController: SelectUserDelegate {
    
    func didSelectUser(user: User, identifier: String) {
        
        if identifier == "Friend" {
            
            transaction.toUser = user
        }
        if identifier == "User" {
        
            transaction.fromUser = user
            transaction.toUser = nil
        }
        
        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}