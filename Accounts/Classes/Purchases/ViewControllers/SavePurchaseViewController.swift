//
//  SavePurchaseViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
 
import Parse
import SwiftyJSON

class SavePurchaseViewController: SaveItemViewController {
    
    var purchase = Purchase.withDefaultValues()
    var purchaseObjectId: String?
    var existingPurchase: Purchase?
    
    var billSplitCells = Dictionary<User, FormViewTextFieldCell>()
    var formViewCells = Dictionary<String, FormViewTextFieldCell>()
    var toolbar = UIToolbar()
    var splitButtons = [UIBarButtonItem]()
    var transactionTextFieldsIndexPaths = Dictionary<UITextField, NSIndexPath>()
    
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
        setupToolbar()
        enableOrDisableSplitButtons()
        
        askToPopMessage = "Going back will discard any changes, Are you sure?"
    }
    
    func setupToolbar() {

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.sizeToFit()
        view.addSubview(toolbar)
        
        toolbar.addHeightConstraint(relation: .Equal, constant: toolbar.frame.height)
        toolbar.addLeftConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addRightConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        let previousInsets = tableView.contentInset
        tableView.contentInset = UIEdgeInsets(top: previousInsets.top, left: previousInsets.left, bottom: previousInsets.bottom + toolbar.frame.height, right: previousInsets.right)
        
        toolbar.tintColor = kNavigationBarTintColor
        
        let splitButton = UIBarButtonItem(title: "Split bill equally", style: .Plain, target: self, action: "splitBillEqually")
        splitButtons.append(splitButton)
        toolbar.items = [splitButton]
    }
    
    func enableOrDisableSplitButtons() {
        
        var count = 0
        
        for t in purchase.transactions {
            
            if t.amount != (self.purchase.amount / Double(self.purchase.transactions.count)) {
                
                count++
            }
        }
        
        let isSplit = count > 0
        
        for splitButton in splitButtons {
            
            splitButton.enabled = purchase.transactions.count > 1 && isSplit
        }
    }
    
    override func reloadForm() {
        super.reloadForm()
        
        enableOrDisableSplitButtons()
    }
    
    func save() {
        
        isSaving = true
        updateUIForSavingOrDeleting()
        
        //var copyOfOriginalForIfSaveFails = existingPurchase?.copyWithUsefulValues()
        
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
        
        var didDoCallback = false
        
        purchase?.savePurchase({ (success) -> () in
            
            NSTimer.schedule(delay: kSaveTimeoutForRemoteUpdate){ timer in
                
                if !didDoCallback {

                    completion()
                    didDoCallback = true
                }
            }
            
        }, remoteCompletion: { () -> () in

            if !didDoCallback {
                
                completion()
                didDoCallback = true
            }
        })
    }
    
    override func saveButtonEnabled() -> Bool {
        
        return allowEditing && purchase.modelIsValid() && !isSaving
    }
    
//    func scrollTransactionCellsToView() {
//        
//
//    }
    
    func textFieldDidBecomeActive(textField: UITextField) {
        
//        if let indexPath = transactionTextFieldsIndexPaths[textField] {
//            
//            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
//        }
    }
    
    func splitBillEqually() {
        
        purchase.resetBillSplitChanges()
        purchase.splitTheBill(nil)
        setFriendAmountTextFields()
    }
    
    // MARK: - FormViewDelegate
    
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
                
                let ex = User.isCurrentUser(transaction.toUser) ? "r" : "'s"
                let verb = "\(ex) part"
                let textLabelText = "(\(transaction.toUser!.appropriateShortDisplayName())\(verb))"
                
                
                transactionConfigs.append(FormViewConfiguration.textFieldCurrency(textLabelText, value: Formatter.formatCurrencyAsString(transaction.amount), identifier: "transactionTo\(transaction.toUser!.objectId)", locale: locale))
            }
        }
        
        // get all others
        for transaction in purchase.transactions {
            
            if transaction.toUser?.objectId != purchase.user.objectId {
                
                let s: String = transaction.toUser?.objectId == User.currentUser()?.objectId ? "" : "s"
                let textLabelText = "\(transaction.toUser!.appropriateShortDisplayName()) owe\(s)"
                
                transactionConfigs.append(FormViewConfiguration.textFieldCurrency(textLabelText, value: Formatter.formatCurrencyAsString(transaction.amount), identifier: "transactionTo\(transaction.toUser!.objectId)", locale: locale))
            }
        }
        
        sections.append(transactionConfigs)
        
        let purchasedDate = purchase.purchasedDate != nil ? purchase.purchasedDate : NSDate()
        
        sections.append([
            FormViewConfiguration.datePicker("Date Purchased", date: purchasedDate, identifier: "DatePurchased", format: nil),
            //FormViewConfiguration.normalCell("Location")
            ])
        
        sections.append([
            FormViewConfiguration.switchCell("Secure", isOn: purchase.isSecure, identifier: "isSecure")
        ])
        
        if purchaseObjectId != nil {
            
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
                ])
        }
        
        return sections
    }
    
    override func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
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
    
    override func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double) {
        
        if identifier == "Amount" {
            
            purchase.localeAmount = value
            purchase.resetBillSplitChanges()
            purchase.splitTheBill(nil)
            
        }
        
        for transaction in purchase.transactions {
            
            if identifier == "transactionTo\(transaction.toUser!.objectId)" {
                
                transaction.amount = value
                
                //purchase.calculateTotalFromTransactions()
                //purchase.billSplitChanges[transaction.toUser!.objectId!] = value
                setTextFieldValueAndUpdateConfig(identifier, value: Formatter.formatCurrencyAsString(value), cell: billSplitCells[transaction.toUser!])
            }
        }
        
        let id = identifier.replaceString("transactionTo", withString: "").replaceString("Optional(", withString: "").replaceString(")", withString: "").replaceString("\"", withString: "")
        purchase.splitTheBill(id)
        
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
        
        enableOrDisableSplitButtons()
    }
    
    override func formViewButtonTapped(identifier: String) {
        
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
    
    override func formViewDidSelectRow(identifier: String) {
        
        if identifier == "Friends" {
            
            let usersToChooseFrom = User.userListExcludingID(purchase.user.objectId)
            
            let v = SelectUsersViewController(identifier: identifier, users: purchase.usersInTransactions(), selectUsersDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom, isInsidePopover: false)
            navigationController?.pushViewController(v, animated: true)
        }
        
        if identifier == "User" {
            
            let usersToChooseFrom = User.userListExcludingID(nil)
            
            let v = SelectUsersViewController(identifier: identifier, user: purchase.user, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom, isInsidePopover: false)
            navigationController?.pushViewController(v, animated: true)
        }
    }
    
    override func formViewDateChanged(identifier: String, date: NSDate) {
        
        if identifier == "DatePurchased" {
            
            purchase.purchasedDate = date
        }
    }
    
    override func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "")
        
        if identifier == "Friends" {
            
            cell.textLabel?.text = "Split with"
            
            //var friendCount = purchase.transactions.count - 1
            
            cell.detailTextLabel?.text = "Tap to select"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        else if identifier == "User" {
            
            cell.textLabel?.text = "Bill settled by "
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
    
    override func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        showOrHideSaveButton()
        enableOrDisableSplitButtons()
        itemDidChange = true
    }

    override func formViewSwitchChanged(identifier: String, on: Bool) {
        
        if identifier == "isSecure" {
            
            purchase.isSecure = on
        }
    }
}


extension SavePurchaseViewController {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if let cell = cell as? FormViewTextFieldCell {
            
            cell.label.textColor = UIColor.blackColor()
            cell.textField.textColor = UIColor.lightGrayColor()
            formViewCells[cell.config.identifier] = cell
            
            transactionTextFieldsIndexPaths[cell.textField] = indexPath
            cell.textField.addTarget(self, action: "textFieldDidBecomeActive:", forControlEvents: UIControlEvents.EditingDidBegin)
            
            //hacky way to set friend cells
            if indexPath.section == 1 {
                
                let i = indexPath.row - 1 // was 2
                
                if i >= 0 {
                    
                    let friend = purchase.usersInTransactions()[i]
                    billSplitCells[friend] = cell
                    
                    if let toolbar = cell.textField.inputAccessoryView as? UIToolbar {
                        
                        let button = UIBarButtonItem(title: "Split bill equally", style: .Plain, target: self, action: "splitBillEqually")
                        splitButtons.append(button)
                        toolbar.items?.insert(button, atIndex: 0)
                        enableOrDisableSplitButtons()
                    }
                }
            }
        }
        return cell
    }
    
    func moveInput(from: Int, to: Int) {
        
        
    }
    
   
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
        //hacky way to set friend cells
        if indexPath.section == 1 {
            
            let i = indexPath.row - 1 // was 2
            
            if i >= 0 {
                
                //tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
            }
        }
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
                    purchase.removeBillSplitChange(friend.objectId)
                    purchase.splitTheBill(nil)
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
            purchase.splitTheBill(nil)
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
            purchase.resetBillSplitChanges()
            purchase.splitTheBill(nil)
        }
        
        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}