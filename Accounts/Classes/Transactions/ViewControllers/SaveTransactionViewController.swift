//
//  SaveTransactionViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 08/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
 
import SwiftyUserDefaults
import SwiftyJSON
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
            
            Task.sharedTasker().executeTaskInBackground({ () -> Void in
                
                self.transaction.fetchIfNeeded()
                self.transaction.toUser?.fetchIfNeeded()
                self.transaction.fromUser?.fetchIfNeeded()
                self.isNew = false
                
            }, completion: { () -> () in
                
                self.updateUIForEditing()
                self.reloadForm()
            })
        }
        
        askToPopMessage = "Going back will discard any changes, Are you sure?"
    }
    
    func save() {

        isSaving = true
        updateUIForSavingOrDeleting()
        
        //_ = existingTransaction?.copyWithUsefulValues()
        
        Transaction.calculateOfflineOweValuesByDeletingTransaction(existingTransaction)
        Transaction.calculateOfflineOweValuesWithTransaction(self.transaction)
        
        let transaction = isExistingTransaction ? existingTransaction : self.transaction
        
        if isExistingTransaction {
            
            transaction?.setUsefulValuesFromCopy(self.transaction)
        }
        
        var delegateCallbackHasBeenFired = false
        
        showSavingOverlay()
        
        transaction?.saveEventually { (success, error) -> Void in

            if success {

                transaction?.pinInBackgroundWithBlock({ (success, error) -> Void in
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationCenterSaveEventuallyItemDidSaveKey, object: nil, userInfo: nil)
                    
                    if !delegateCallbackHasBeenFired {
                        
                        self.delegate?.itemDidChange()
                        self.delegate?.transactionDidChange(transaction!)
                        delegateCallbackHasBeenFired = true
                        self.popAll()
                    }
                })
            }
            else{
                
                ParseUtilities.showAlertWithErrorIfExists(error)
            }
        }

        NSTimer.schedule(delay: kSaveTimeoutForRemoteUpdate) { timer in
            
            if !delegateCallbackHasBeenFired {
                
                self.delegate?.itemDidChange()
                self.delegate?.transactionDidChange(transaction!)
                delegateCallbackHasBeenFired = true
                self.popAll()
            }
        }
    }
    
    override func saveButtonEnabled() -> Bool {
        
        return allowEditing && transaction.modelIsValid() && !isSaving
    }
    
    func selectPlace() {
        
        //var view = SelectLocationViewController()
        //navigationController?.pushViewController(view, animated: true)
    }
    
    // MARK: - Form view delegate 
    
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
        
        if transaction.purchaseTransactionLinkUUID != nil {
            
            sections.append([
                FormViewConfiguration.normalCell("PurchaseInfo")
                ])
        }
        
//        sections.append([
//            FormViewConfiguration.switchCell("Secure", isOn: transaction.isSecure, identifier: "isSecure")
//        ])
        
        if isExistingTransaction && allowEditing {
            
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
            ])
        }
        
        return sections
    }
    
    override func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
        
        if identifier == "Friend" || identifier == "User" {
            
            let label = UILabel()
            label.font = UIFont.normalFont(17)
            label.textAlignment = .Center
            label.textColor = .blackColor()
            
            label.translatesAutoresizingMaskIntoConstraints = false
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
            //        else if identifier == "Location" {
            //
            //            cell.textLabel?.text = "Location"
            //            cell.detailTextLabel?.text = "None"
            //            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            //        }
        else if identifier == "PurchaseInfo" {
            
            let cell = TransactionPurchaseInfoTableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
            cell.transaction = transaction
            cell.setup()
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    override func formViewDateChanged(identifier: String, date: NSDate) {
        
        if identifier == "TransactionDate" {
            
            transaction.transactionDate = date
        }
    }
    
    override func formViewSwitchChanged(identifier: String, on: Bool) {
        
        if identifier == "isSecure" {
            
            transaction.isSecure = on
        }
    }
    
    override func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        if identifier == "Title" {
            
            transaction.title = text
        }
    }
    
    override func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double) {
        
        if identifier == "Amount" {
            
            transaction.localeAmount = value
        }
    }
    
    override func formViewButtonTapped(identifier: String) {
        
        if identifier == "Delete" {
            
            UIAlertController.showAlertControllerWithButtonTitle("Delete", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Delete transaction: \(self.transaction.title!) for \(Formatter.formatCurrencyAsString(transaction.localeAmount))?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.updateUIForSavingOrDeleting()
                    self.navigationItem.rightBarButtonItem?.enabled = false
                    
                    let transaction = self.isExistingTransaction ? self.existingTransaction : self.transaction
                    
                    IOSession.sharedSession().deletedTransactionIds.append(String.emptyIfNull(transaction?.objectId))
                    
                    self.isSaving = true
                    
                    Transaction.calculateOfflineOweValuesByDeletingTransaction(self.existingTransaction)
                    
                    transaction?.deleteEventually()
                    transaction?.isDeleted = true
                    
                    self.showDeletingOverlay()
                    
                    NSTimer.schedule(delay: kDeleteTimeoutForRemoteUpdate) { timer in
                        
                        self.popAll()
                        self.delegate?.itemDidGetDeleted()
                    }
                }
            })
        }
    }
    
    override func formViewDidSelectRow(identifier: String) {
        
        if allowEditing {
            
            if identifier == "Friend" {
                
                let usersToChooseFrom = User.userListExcludingID(nil) // User.userListExcludingID(transaction.fromUser?.objectId)
                
                let v = SelectUsersViewController(identifier: identifier, user: transaction.toUser, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom, isInsidePopover: isInsidePopover)
                navigationController?.pushViewController(v, animated: true)
            }
            else if identifier == "User" {
                
                let usersToChooseFrom = User.userListExcludingID(nil)
                
                let v = SelectUsersViewController(identifier: identifier, user: transaction.fromUser, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom, isInsidePopover: isInsidePopover)
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
        
        if identifier == "isSecure" {
            
            return User.currentUser()?.userType == UserType.ProUser.rawValue && allowEditing
        }
        
        return allowEditing
    }
    
    override func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        showOrHideSaveButton()
        itemDidChange = true
    }

    // MARK: - Table view
    
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
            
            let view = UIView()
            
            let label = UILabel()
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
            
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            label.fillSuperView(UIEdgeInsets(top: 0, left: 0, bottom: 17, right: 0))
            
            return view
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if transaction.purchaseTransactionLinkUUID != nil {
            
            if let indexPath = indexPathForFormViewCellIdentifier("PurchaseInfo") {
                
                if indexPath.section == section {
                    
                    return "This transaction is linked with a bill that was split. The total of that bill is shown here. (read only)"
                }
            }
        }
        
        if let indexPath = indexPathForFormViewCellIdentifier("isSecure"){
            
            if section == indexPath.section {
                
                return kIsSecureDescription
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