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
import GoogleMaps
//import Reachability
import SwiftOverlays

class SaveTransactionViewController: SaveItemViewController {

    var transaction = Transaction.withDefaultValues()
    var isNew = true
    var transactionObjectId: String?
    var existingTransaction: Transaction?
    var isExistingTransaction = false
    
    override func viewDidLoad() {

        shouldLoadFormOnLoad = false
        super.viewDidLoad()

        allowEditing = true // = transaction.purchaseTransactionLinkUUID == nil // transaction.TransactionID == 0 || transaction.user.UserID == kActiveUser.UserID
        
        showOrHideSaveButton()
        reloadForm()
        
        if allowEditing && !isExistingTransaction {
            
            title = transaction.type == .iou ? "Add i.o.u" : "Add payment"
        }
        else if allowEditing && isExistingTransaction {
            
            title = transaction.type == .iou ? "Edit i.o.u" : "Edit payment"
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

        isSaving = true
        updateUIForSavingOrDeleting()
        
        var copyOfOriginalForIfSaveFails = existingTransaction?.copyWithUsefulValues()
        
        let transaction = isExistingTransaction ? existingTransaction : self.transaction
        
        if isExistingTransaction {
            
            transaction?.setUsefulValuesFromCopy(self.transaction)
        }
        
        var delegateCallbackHasBeenFired = false
        
        showSavingOverlay()
        
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
    
    func selectPlace() {
        
        var view = SelectLocationViewController()
        navigationController?.pushViewController(view, animated: true)
    }
}

extension SaveTransactionViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        let locale = Settings.getCurrencyLocaleWithIdentifier().locale
        
        var sections = Array<Array<FormViewConfiguration>>()
        
        if transaction.type == TransactionType.iou {
            
            sections.append([
                FormViewConfiguration.normalCell("Friend")
            ])
            
            sections.append([
                FormViewConfiguration.normalCell("User")
            ])
        }
        else if transaction.type == TransactionType.payment {
            
            sections.append([
                FormViewConfiguration.normalCell("User")
            ])
            
            sections.append([
                FormViewConfiguration.normalCell("Friend")
            ])
        }

        sections.append([
            FormViewConfiguration.textFieldCurrency("Amount", value: Formatter.formatCurrencyAsString(transaction.localeAmount), identifier: "Amount", locale: locale),
            FormViewConfiguration.textField("Title", value: String.emptyIfNull(transaction.title), identifier: "Title"),
            FormViewConfiguration.datePicker("Transaction date", date: transaction.transactionDate, identifier: "TransactionDate", format: nil)
            //FormViewConfiguration.normalCell("Location")
        ])
        
        if isExistingTransaction && allowEditing {
            
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
            ])
        }
        
        return sections
    }
    
    func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
        
        if identifier == "Friend" || identifier == "User" {
            
            var label = UILabel()
            label.font = UIFont.normalFont(17)
            label.textAlignment = .Center
            label.textColor = .blackColor()
            
            label.setTranslatesAutoresizingMaskIntoConstraints(false)
            cell.contentView.addSubview(label)
            label.fillSuperView(UIEdgeInsetsZero)
            
            if identifier == "Friend" {
                
                if let username = transaction.toUser?.appropriateDisplayName() {
                 
                    label.text = username
                }
                else {
                    
                    label.text = "Tap to select user"
                    label.textColor = UIColor.lightGrayColor()
                }
            }
            
            if identifier == "User" {
             
                if let username = transaction.fromUser?.appropriateDisplayName() {
                    
                    label.text = username
                }
                else {
                    
                    label.text = "Tap to select user"
                    label.textColor = UIColor.lightGrayColor()
                }
            }
            
            return cell
        }
        else if identifier == "Location" {
            
            cell.textLabel?.text = "Location"
            cell.detailTextLabel?.text = "None"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
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
                    
                    self.isSaving = true
                    transaction?.deleteEventually()
                    
                    self.showDeletingOverlay()
                    
                    NSTimer.schedule(delay: 2.5) { timer in
                        
                        self.popAll()
                        self.delegate?.itemDidGetDeleted()
                    }
                }
            })
        }
    }
    
    func formViewDidSelectRow(identifier: String) {
        
        if allowEditing {
            
            if identifier == "Friend" {
                
                let usersToChooseFrom = User.userListExcludingID(nil) // User.userListExcludingID(transaction.fromUser?.objectId)
                
                let v = SelectUsersViewController(identifier: identifier, user: transaction.toUser, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
                navigationController?.pushViewController(v, animated: true)
            }
            else if identifier == "User" {
                
                let usersToChooseFrom = User.userListExcludingID(nil)
                
                let v = SelectUsersViewController(identifier: identifier, user: transaction.fromUser, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
                navigationController?.pushViewController(v, animated: true)
            }
            else if identifier == "Location" {
                
                selectPlace()
            }
        }
        else {
            
            deselectSelectedCell(tableView)
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
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        if section == 0 {
            
            var view = UIView()
            
            var label = UILabel()
            label.font = UIFont(name: "Helvetica-Light", size: 14)
            label.textAlignment = NSTextAlignment.Center
            
            var verb = "owe"
            var s: String = User.isCurrentUser(transaction.toUser) ? "" : "s"
            
            if transaction.type == TransactionType.payment {
                
                verb = "paid"
                s = ""
            }
            
            label.text = "- \(verb)\(s) -"
            label.textColor = .darkGrayColor()
            
            label.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.addSubview(label)
            label.fillSuperView(UIEdgeInsets(top: 0, left: 0, bottom: 17, right: 0))
            
            return view
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if !isExistingTransaction {
            
            if section == numberOfSectionsInTableView(tableView) - 1 {
                
                if transaction.type == TransactionType.iou {
                    
                    return "Use this form to log when you owe one of your friends some money, or if they owe you."
                }
                else if transaction.type == TransactionType.payment {
                    
                    return "Use this form to log when you paid or got paid some money by one of your friends."
                }
            }
            
        }

        return nil
    }
}

extension SaveTransactionViewController: SelectUserDelegate {
    
    func didSelectUser(user: User, identifier: String) {
        
        if identifier == "Friend" {
            
            transaction.toUser = user
            
            if transaction.fromUser?.objectId == user.objectId {
                
                transaction.fromUser = nil
            }
        }
        if identifier == "User" {
        
            transaction.fromUser = user
            
            if transaction.toUser?.objectId == user.objectId {
                
                transaction.toUser = nil
            }
        }
        
        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}