//
//  SavePurchaseViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit
import Parse
import SwiftyJSON

class SavePurchaseViewController: SaveItemViewController {

    var purchase = Purchase.withDefaultValues()
    var purchaseObjectId: String?
    var existingPurchase: Purchase?
    
    var billSplitCells = Dictionary<User, FormViewTextFieldCell>()
    var formViewCells = Dictionary<String, FormViewTextFieldCell>()
    var billSplitChanges = Dictionary<String, String?>()
    
    override func viewDidLoad() {
        
        shouldLoadFormOnLoad = false
        super.viewDidLoad()
        
        allowEditing = true // dont allow editing on existing purchase

        if allowEditing && purchaseObjectId == nil {

            title = "Split a bill"
            purchase.user = User.currentUser()!
            purchase.title = ""
            purchase.purchasedDate = NSDate()
            
            let transaction = Transaction()
            transaction.fromUser = User.currentUser()
            transaction.toUser = User.currentUser()
            transaction.amount = 0
            
            purchase.transactions.append(transaction)
            
            updateUIForEditing()
        }
        else if allowEditing && purchaseObjectId != nil {

            title = "Edit purchase" // N/A
        }
        else {
            
            title = "Split a bill"
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "askToPopIfChanged")
        
        tableView.setEditing(true, animated: false)

        reloadForm()

        askToPopMessage = "Going back will discard any changes, Are you sure?"
    }
        
    func save() {

        isSaving = true
        updateUIForSavingOrDeleting()
        
        var copyOfOriginalForIfSaveFails = existingPurchase?.copyWithUsefulValues()
        
        let purchase = purchaseObjectId != nil ? existingPurchase : self.purchase
        
        if purchaseObjectId != nil {
            
            purchase?.setUsefulValuesFromCopy(self.purchase)
        }
        
        showSavingOverlay()
        
        let completion: () -> () = {
            
            self.delegate?.itemDidChange()
            self.delegate?.purchaseDidChange(purchase!)
            self.popAll()
        }
        
        var didCompleteRemotely = false
        
        purchase?.savePurchase({ (success) -> () in
            
            NSTimer.schedule(delay: kSaveTimeoutForRemoteUpdate){ timer in
                
                if !didCompleteRemotely {
                    
                    completion()
                }
            }
            
        }, remoteCompletion: { () -> () in
            
            completion()
            didCompleteRemotely = true
        })
    }
    
    override func saveButtonEnabled() -> Bool {
        
        return allowEditing && purchase.modelIsValid() && !isSaving
    }
}

extension SavePurchaseViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        let locale: NSLocale? = Settings.getCurrencyLocaleWithIdentifier().locale
        
        var sections = Array<Array<FormViewConfiguration>>()

        sections.append([
            FormViewConfiguration.textFieldCurrency("Bill total", value: Formatter.formatCurrencyAsString(purchase.localeAmount), identifier: "Amount", locale: locale),
            FormViewConfiguration.textField("Title", value: String.emptyIfNull(purchase.title), identifier: "Title"),
            FormViewConfiguration.normalCell("User"),
            
        ])
        
        var transactionConfigs: Array<FormViewConfiguration> = [
            FormViewConfiguration.normalCell("Friends")
        ]
        
        // get purchase user first
        for transaction in purchase.transactions {
            
            if transaction.toUser?.objectId == purchase.user.objectId {
                
                var ex = User.isCurrentUser(transaction.toUser) ? "r" : "'s"
                var verb = "\(ex) part"
                var textLabelText = "(\(transaction.toUser!.appropriateShortDisplayName())\(verb))"

                
                transactionConfigs.append(FormViewConfiguration.textFieldCurrency(textLabelText, value: Formatter.formatCurrencyAsString(transaction.amount), identifier: "transactionTo\(transaction.toUser!.objectId)", locale: locale))
            }
        }
        
        // get all others
        for transaction in purchase.transactions {
            
            if transaction.toUser?.objectId != purchase.user.objectId {
                
                var s: String = transaction.toUser?.objectId == User.currentUser()?.objectId ? "" : "s"
                var textLabelText = "\(transaction.toUser!.appropriateShortDisplayName()) owe\(s)"
                
                transactionConfigs.append(FormViewConfiguration.textFieldCurrency(textLabelText, value: Formatter.formatCurrencyAsString(transaction.amount), identifier: "transactionTo\(transaction.toUser!.objectId)", locale: locale))
            }
        }
        
        sections.append(transactionConfigs)

        var purchasedDate = purchase.purchasedDate != nil ? purchase.purchasedDate : NSDate()
        
        sections.append([
            FormViewConfiguration.datePicker("Date Purchased", date: purchasedDate, identifier: "DatePurchased", format: nil),
            //FormViewConfiguration.normalCell("Location")
        ])
        
        if purchaseObjectId != nil {
         
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
            ])
        }
        
        return sections
    }
    
    func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        if identifier == "Title" {
            
            purchase.title = text
        }
    }
    
    func setFriendAmountTextFields() {
    
        for transaction in self.purchase.transactions {
        
            self.setTextFieldValueAndUpdateConfig("transactionTo\(transaction.toUser!.objectId)", value: Formatter.formatCurrencyAsString(transaction.amount), cell: self.billSplitCells[transaction.toUser!])
        }
        
        self.setTextFieldValueAndUpdateConfig("Amount", value: Formatter.formatCurrencyAsString(self.purchase.amount), cell: self.formViewCells["Amount"])
        
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 1)], withRowAnimation: .None)
    }
    
    func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double) {
        
        if identifier == "Amount" {
            
            purchase.localeAmount = value
            billSplitChanges.removeAll(keepCapacity: false)
            purchase.splitTheBill(&billSplitChanges, givePriorityTo: nil)
        }
        
        for transaction in purchase.transactions {
            
            if identifier == "transactionTo\(transaction.toUser!.objectId)" {
                
                transaction.amount = value
                
                //purchase.calculateTotalFromTransactions()
                billSplitChanges[transaction.toUser!.objectId!] = transaction.toUser!.objectId!
                setTextFieldValueAndUpdateConfig(identifier, value: Formatter.formatCurrencyAsString(value), cell: billSplitCells[transaction.toUser!])
            }
        }
        
        let id = identifier.replaceString("transactionTo", withString: "").replaceString("Optional(", withString: "").replaceString(")", withString: "").replaceString("\"", withString: "")
        purchase.splitTheBill(&billSplitChanges, givePriorityTo: id)
        
        setFriendAmountTextFields()
    }
    
    func setTextFieldValueAndUpdateConfig(identifier: String, value: String, cell: FormViewTextFieldCell?) {
        
        if let cell = cell {
            
            let indexPath = indexPathForFormViewCellIdentifier(identifier)!
            
            let config = data[indexPath.section][indexPath.row]
            config.value = value
            
            if config.formCellType == FormCellType.TextField {
                
                cell.textField.text = value
            }
            else if config.formCellType == FormCellType.TextFieldCurrency {
                
                cell.textField.text = value
            }
        }
    }
    
    func formViewButtonTapped(identifier: String) {
        
        if identifier == "Delete" {
            
            UIAlertController.showAlertControllerWithButtonTitle("Delete", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Delete purchase: \(purchase.title!) for \(Formatter.formatCurrencyAsString(purchase.localeAmount))?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.updateUIForSavingOrDeleting()
                    
                    let purchase = self.purchaseObjectId != nil ? self.existingPurchase : self.purchase
                    
                    self.showDeletingOverlay()
                    
                    purchase?.deleteInBackgroundWithBlock { (success, error) -> Void in
                        
                        if success {
                            
                            self.popAll()
                            self.delegate?.itemDidGetDeleted()
                        }
                        else{
                            
                            ParseUtilities.showAlertWithErrorIfExists(error)
                        }
                        
                        self.navigationItem.rightBarButtonItem?.enabled = true
                        self.navigationItem.leftBarButtonItem?.enabled = true
                    }
                }
            })
        }
    }
    
    func formViewDidSelectRow(identifier: String) {
        
        if identifier == "Friends" {
            
            let usersToChooseFrom = User.userListExcludingID(purchase.user.objectId)

            let v = SelectUsersViewController(identifier: identifier, users: purchase.usersInTransactions(), selectUsersDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
            navigationController?.pushViewController(v, animated: true)
        }
        
        if identifier == "User" {
            
            let usersToChooseFrom = User.userListExcludingID(nil)
            
            let v = SelectUsersViewController(identifier: identifier, user: purchase.user, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
            navigationController?.pushViewController(v, animated: true)
        }
    }
    
    func formViewDateChanged(identifier: String, date: NSDate) {
        
        if identifier == "DatePurchased" {
            
            purchase.purchasedDate = date
        }
    }
    
    func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "")
        
        if identifier == "Friends" {
            
            cell.textLabel?.text = "Split with"
            
            var friendCount = purchase.transactions.count - 1
            
            cell.detailTextLabel?.text = "\(friendCount)"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        else if identifier == "User" {
            
            cell.textLabel?.text = "Purchased by "
            cell.detailTextLabel?.text = "\(purchase.user.appropriateDisplayName())"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        else if identifier == "Location" {
            
            //cell.imageView?.image = AppTools.iconAssetNamed("07-map-marker.png")
            cell.textLabel?.text = "Location"
            cell.detailTextLabel?.text = "None"
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func formViewElementIsEditable(identifier: String) -> Bool {
        
        return allowEditing
    }
    
    func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        showOrHideSaveButton()
        itemDidChange = true
    }
}

extension SavePurchaseViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if let cell = cell as? FormViewTextFieldCell {
            
            cell.label.textColor = UIColor.blackColor()
            cell.textField.textColor = UIColor.lightGrayColor()
            formViewCells[cell.config.identifier] = cell
            
            //hacky way to set friend cells
            if indexPath.section == 1 {
                
                let i = indexPath.row - 1 // was 2
                
                if i >= 0 {
                    
                    let friend = purchase.usersInTransactions()[i]
                    billSplitCells[friend] = cell
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        //hacky way to set friend cells
        if indexPath.section == 1 {
            
            let i = indexPath.row - 1
            
            if i >= 0 {
                
                return .Delete
            }
        }
        
        return .None
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        //hacky way to set friend cells
        if indexPath.section == 1 {
            
            let i = indexPath.row - 2
            
            if i >= 0 {
                
                return true
            }
        }
        
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            //hacky way to set friend cells
            if indexPath.section == 1 {
                
                let i = indexPath.row - 1
                
                if i >= 0 {
                    
                    let friend = purchase.usersInTransactions()[i]
                    
                    tableView.beginUpdates()
                    
                    billSplitCells.removeValueForKey(friend)
                    purchase.removeTransactionForToUser(friend)
                    
                    if billSplitChanges[friend.objectId!] != nil {
                        
                        billSplitChanges.removeValueForKey(friend.objectId!)
                    }
                    
                    //
                    purchase.splitTheBill(&billSplitChanges, givePriorityTo: nil)
                    //purchase.calculateTotalFromBillSplitDictionary()
                    setFriendAmountTextFields()
                    
                    data[indexPath.section].removeAtIndex(indexPath.row)

                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
                    tableView.endUpdates()
                    
                    itemDidChange = true
                }
            }
        }
        
        showOrHideSaveButton()
    }
}

extension SavePurchaseViewController: SelectUsersDelegate {

    func didSelectUsers(users: Array<User>, identifier: String) {

        billSplitCells = Dictionary<User, FormViewTextFieldCell>()
        
        if identifier == "Friends" {
            
            purchase.transactions = []
            
            for user in users {
                
                let transaction = Transaction()
                transaction.fromUser = User.currentUser()
                transaction.toUser = user
                purchase.transactions.append(transaction)
            }
            
            let transaction = Transaction()
            transaction.fromUser = purchase.user
            transaction.toUser = purchase.user
            transaction.amount = 0
            purchase.transactions.append(transaction)
            
            //billSplitChanges.removeAll(keepCapacity: false)
            purchase.splitTheBill(&billSplitChanges, givePriorityTo: nil)
        }

        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}

extension SavePurchaseViewController: SelectUserDelegate {
    
    func didSelectUser(user: User, identifier: String) {
        
        if identifier == "User" {
            
            purchase.user = user
            purchase.transactions = []
            
            let transaction = Transaction()
            transaction.fromUser = user
            transaction.toUser = user
            transaction.amount = 0
            purchase.transactions.append(transaction)
            billSplitChanges = Dictionary<String, String?>()
            purchase.splitTheBill(&billSplitChanges, givePriorityTo: nil)
        }
        
        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}