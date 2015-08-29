//
//  Purchase.swift
//  Accounts
//
//  Created by Alex Bechmann on 21/04/2015.
//  Copyright (c) 2015 Ustwo. All rights reserved.
//

import UIKit
import ABToolKit
import Alamofire
import SwiftyJSON
import Parse

class Purchase: PFObject {

    @NSManaged var title: String?
    @NSManaged var user: User
    @NSManaged var purchasedDate:NSDate?
    @NSManaged var purchaseTransactionLinkUUID: String?
    
    var amount: Double = 0
    var transactions: Array<Transaction> = []
    var preferredValues = Dictionary<String, Double>()
    //var shouldGetValuesNextTimeFromPreferredValues = false
    
    class func withDefaultValues() -> Purchase{
        
        let purchase = Purchase()
        purchase.user = User.currentUser()!
        purchase.transactions = []
        purchase.amount = 0
        purchase.title = ""
        
        return purchase
    }
    
    var localeAmount: Double {
        
        get {
            
            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
            
            if currencyIdentifier == "DKK" {
                
                return self.amount * 10
            }
            else {
                
                return self.amount
            }
        }
        
        set(newValue) {
            
            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
            
            if currencyIdentifier == "DKK" {
                
                self.amount = newValue / 10
            }
            else {
                
                self.amount = newValue
            }
        }
    }
    
    func savePurchase(initialCompletion: (success:Bool) -> (), remoteCompletion: () -> ()) {
        
        var isNewPurchase = objectId == nil
        
        if !modelIsValid() {

            initialCompletion(success: false)
            return
        }
        
        if purchaseTransactionLinkUUID == nil {
            
            purchaseTransactionLinkUUID = NSUUID().UUIDString
        }

        saveEventually({ (success, error) -> Void in
            
            //NSNotificationCenter.defaultCenter().postNotificationName(kNotificationCenterSaveEventuallyItemDidSaveKey, object: nil, userInfo: nil)
        })
        
        var transactionsCompleted = 0
        
        for transaction in transactions {
            
            transaction.transactionDate = purchasedDate!
            transaction.fromUser = user
            transaction.title = title
            transaction.purchase = self
            transaction.purchaseTransactionLinkUUID = purchaseTransactionLinkUUID
            
            if transaction.fromUser != transaction.toUser{
                
                Transaction.calculateOfflineOweValuesWithTransaction(transaction)
                
                transaction.saveEventually({ (success, error) -> Void in
                    
                    transactionsCompleted++

                    if transactionsCompleted == (self.transactions.count - 1) { // - 1 for one to urself

                        remoteCompletion()
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationCenterSaveEventuallyItemDidSaveKey, object: nil, userInfo: nil)
                })

                initialCompletion(success: true)
            }
        }
    }
    
    func transactionTotalsEqualsTotal() -> Bool {
        
        var totalCheck:Double = 0
        
        for transaction in self.transactions {
            
            totalCheck += transaction.amount
        }
        
        if totalCheck != self.amount {
            
            println("ERRORRORRR")
        }
        println(totalCheck) ; println(self.amount)
        return totalCheck == self.amount
    }
    
    func transactionsInChangeList() -> [Transaction] {
        
        return self.transactions.filter({ (t) -> Bool in
            
            var rc = false
            
            if let toUser = t.toUser {
                
                rc = self.billSplitChanges[toUser.objectId!] != nil
            }
            
            return rc
        })
    }
    
    func transactionsNotInChangeList() -> [Transaction] {
        
        return self.transactions.filter({ (t) -> Bool in
            
            var rc = false
            
            if let toUser = t.toUser {
                
                rc = self.billSplitChanges[toUser.objectId!] == nil
            }
            
            return rc
        })
    }
    
    var billSplitChanges = Dictionary<String, Double>()
    
    func splitTheBill(currentFieldToUserId: String?) { //, editingTransaction: Transaction?) {
        
        if let currentTransaction = transactionForToUserId(currentFieldToUserId) {
            
            currentTransaction.amount = currentTransaction.amount > self.amount ? self.amount : currentTransaction.amount
            billSplitChanges[currentFieldToUserId!] = currentTransaction.amount
        }
        
        if billSplitChanges.count < self.transactions.count{
            
            var extraUnprocessedIds = [String]()
            var remainding = self.amount
            
            if let currentTransaction = transactionForToUserId(currentFieldToUserId) {
                
                println("current transaction: \(currentTransaction.amount) ")
                remainding -= currentTransaction.amount
                println("remainder: \(remainding)")
            }
            
            for change in billSplitChanges {
                
                var toUserId: String = change.0
                var amount: Double = change.1
                
                if toUserId != currentFieldToUserId {
                    
                    if remainding - amount >= 0 {
                        
                        remainding -= amount
                    }
                    else {
                        
                        extraUnprocessedIds.append(toUserId)
                    }
                }
                
                println("remainder #2: \(remainding)")
            }
            
            var transactionsToChange = transactionsNotInChangeList()
            
            for id in extraUnprocessedIds {
                
                transactionsToChange.append(transactionForToUserId(id)!)
            }
            
            for transaction in transactionsToChange {
                
                if transaction.toUser?.objectId == currentFieldToUserId {
                    
                    transactionsToChange.removeAtIndex(
                        find(transactionsToChange, transaction)!
                    )
                }
            }
            
            let splitAmount = remainding / Double(transactionsToChange.count)
            
            for transaction in transactionsToChange {

                transaction.amount = splitAmount
                billSplitChanges.removeValueForKey(transaction.toUser!.objectId!)
            }
        }
        else {
            
            // split equally
            let splitAmount = self.amount / Double(transactions.count)
            
            for transaction in transactions {
                
                transaction.amount = splitAmount
            }
            
            billSplitChanges.removeAll(keepCapacity: false)
        }
    }

    func billSplitChangesNotIncluding(id: String?) -> Dictionary<String, Double> {
        
        var billSplitChanges = Dictionary<String, Double>()
        
        for change in self.billSplitChanges {
            
            billSplitChanges[change.0] = change.1
        }
        
        if let id = id {
            
            billSplitChanges.removeValueForKey(id)
        }
        
        return billSplitChanges
    }
    
    func modelIsValid() -> Bool {

        var errors:Array<String> = []
        
        if amount == 0 {
         
            errors.append("Amount is 0")
        }
        
        if transactions.count < 2 {
            
            errors.append("You havnt split this with anyone!")
        }
        
        if String.emptyIfNull(title) == "" {
            
            errors.append("title is empty")
        }
        
        var friendTotals:Double = 0
        
        var c = 1
        var errorMessageString = ""
        
        for error in errors {
            
            let suffix = c == errors.count ? "" : ", "
            errorMessageString += "\(error)\(suffix)"
            c++
        }
        
        if errors.count > 0 {
            
            //UIAlertView(title: "Purchase not saved!", message: errorMessageString, delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        return errors.count > 0 ? false : true
    }
    
    func calculateTotalFromTransactions(transactions:[Transaction]) -> Double {
        
        var amount: Double = 0
        
        for transaction in transactions {
            
            amount += transaction.amount
        }
        
        return amount
    }
    
    func transactionForToUser(toUser: User) -> Transaction? {
        
        for transaction in transactions {
            
            if transaction.toUser == toUser {
                
                return transaction
            }
        }
        
        return nil
    }
    
    func transactionForToUserId(id: String?) -> Transaction? {
        
        for transaction in transactions {
            
            if transaction.toUser?.objectId == id {
                
                return transaction
            }
        }
        
        return nil
    }
    
    func usersInTransactions() -> Array<User> {
        
        var users = Array<User>()
        
        // get purchase user first
        for transaction in transactions {
            
            if transaction.toUser?.objectId == user.objectId {
                
                users.append(transaction.toUser!)
            }
        }
        
        // get all others
        for transaction in transactions {
            
            if transaction.toUser?.objectId != user.objectId {
                
                users.append(transaction.toUser!)
            }
        }
        
        return users
    }
    
    func removeTransactionForToUser(toUser: User) {
        
        for transaction in transactions {
            
            if transaction.toUser == toUser {
                
                let index = find(transactions, transaction)!
                transactions.removeAtIndex(index)
            }
        }
    }
    
    func hardUnpin() {
        
        Task.executeTaskInBackground({ () -> () in
            
            PFObject.unpinAll(self.transactions)
            self.unpin()
            
        }, completion: { () -> () in
            
            
        })
    }
    
    func copyWithUsefulValues() -> Purchase {
        
        var purchase = Purchase()
        
        purchase.user = user
        purchase.amount = amount
        purchase.title = title
        purchase.purchasedDate = purchasedDate
        purchase.transactions = []
        
        for transaction in transactions {
            
            purchase.transactions.append(transaction.copyWithUsefulValues())
        }
        
        return purchase
    }
    
    func setUsefulValuesFromCopy(purchase: Purchase) {
        
        user = purchase.user
        amount = purchase.amount
        title = purchase.title
        purchasedDate = purchase.purchasedDate
        transactions = purchase.transactions
    }
}

extension Purchase: PFSubclassing {
    
    static func parseClassName() -> String {
        return Purchase.getClassName()
    }
}