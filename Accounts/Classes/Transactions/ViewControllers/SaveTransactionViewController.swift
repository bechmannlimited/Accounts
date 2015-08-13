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
import SwiftyJSON
//import Reachability

class SaveTransactionViewController: SaveItemViewController {

    var transaction = Transaction.withDefaultValues()
    var isNew = true
    var transactionObjectId: String?
    var existingTransaction: Transaction?
    var isExistingTransaction = false
    
    override func viewDidLoad() {

        shouldLoadFormOnLoad = false
        super.viewDidLoad()
        
        showOrHideSaveButton()
        reloadForm()

        allowEditing = true // transaction.TransactionID == 0 || transaction.user.UserID == kActiveUser.UserID
        
        if allowEditing && !isExistingTransaction {
            
            title = "Add i.o.u"
        }
        else if allowEditing && isExistingTransaction {
            
            title = "Edit i.o.u"
        }
        else {
            
            title = "i.o.u"
        }
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "askToPopIfChanged")
        
        if transactionObjectId != nil {
            
            updateUIForServerInteraction()
            
            Task.executeTaskInBackground({ () -> () in
                
//                var error = NSErrorPointer()
//                self.transaction.fetch(error)
//                
//                if error != nil {
//                    
//                    self.pop()
//                }
                self.transaction.fetchIfNeeded()
                self.transaction.toUser?.fetchIfNeeded()
                self.transaction.fromUser?.fetchIfNeeded()
                self.isNew = false
                
            }, completion: { () -> () in
                
                self.updateUIForEditing()
                self.reloadForm()
                
                //self.copyOfItem = ParseUtilities.convertPFObjectToDictionary(self.transaction)
            })
        }
        
        askToPopMessage = "Going back will discard any changes, Are you sure?"
    }
    
    func save() {

        updateUIForSavingOrDeleting()
        
        var copyOfOriginalForIfSaveFails = existingTransaction?.copyWithUsefulValues()
        
        let transaction = isExistingTransaction ? existingTransaction : self.transaction
        
        if isExistingTransaction {
            
            transaction?.setUsefulValuesFromCopy(self.transaction)
        }
        
        var delegateCallbackHasBeenFired = false
        
        transaction?.saveEventually { (success, error) -> Void in

            if success {

                NSTimer.schedule(delay: 2, handler: { timer in
                
                    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationCenterSaveEventuallyItemDidSaveKey, object: nil, userInfo: nil)
                    
                    if !delegateCallbackHasBeenFired {
                    
                        self.delegate?.itemDidChange()
                        self.delegate?.transactionDidChange(transaction!)
                        delegateCallbackHasBeenFired = true
                    }
                })
            }
            else{
                
                //self.existingTransaction?.setUsefulValuesFromCopy(copyOfOriginalForIfSaveFails!) // remove this again?
                ParseUtilities.showAlertWithErrorIfExists(error)
            }

            //self.updateUIForEditing()
        }
        
//        let reachability = Reachability.reachabilityForInternetConnection()
//        
//        reachability.whenUnreachable = { reachability in
//            
//            UIAlertView(title: "No connection", message: "This item will be saved online as soon as a network connection is available.", delegate: nil, cancelButtonTitle: "Ok", otherButtonTitles: nil, nil).show()
//        }
//        
//        reachability.startNotifier()
        
        NSTimer.schedule(delay: 2) { timer in
            
            if !delegateCallbackHasBeenFired {
                
                self.delegate?.itemDidChange()
                self.delegate?.transactionDidChange(transaction!)
                delegateCallbackHasBeenFired = true
            }
            
            self.popAll()
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
        
        if transactionObjectId != nil {
            
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
            ])
        }
        
        return sections
    }
    
    func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
        
        if identifier == "Friend" {
            
            cell.textLabel?.text = "Receiver"
            if let username = transaction.toUser?.appropriateDisplayName() {
                
                cell.detailTextLabel?.text = "\(username)"
            }
            else{
                
                cell.detailTextLabel?.text = ""
            }
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

            return cell
        }
        
        if identifier == "User" {
            
            cell.textLabel?.text = "Payer"
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

            UIAlertController.showAlertControllerWithButtonTitle("Delete", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Delete transaction: \(self.transaction.title!) for \(Formatter.formatCurrencyAsString(transaction.localeAmount))?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.updateUIForSavingOrDeleting()
                    self.navigationItem.rightBarButtonItem?.enabled = false
                    
                    let transaction = self.isExistingTransaction ? self.existingTransaction : self.transaction
                    
                    IOSession.sharedSession().deletedTransactionIds.append(String.emptyIfNull(transaction?.objectId))
                    
                    transaction?.deleteEventually()
                    
                    NSTimer.schedule(delay: 2.5) { timer in
                        
                        self.popAll()
                        self.delegate?.itemDidGetDeleted()
                        self.navigationItem.leftBarButtonItem?.enabled = true // ^^
                    }
                    
                    //ParseUtilities.sendPushNotificationsInBackgroundToUsers(self.transaction.pushNotificationTargets(), message: "Transfer: \(self.transaction.title!) (\(Formatter.formatCurrencyAsString(transaction!.localeAmount))) was deleted by \(User.currentUser()!.appropriateDisplayName())!", data: [kPushNotificationTypeKey : PushNotificationType.ItemSaved.rawValue])
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