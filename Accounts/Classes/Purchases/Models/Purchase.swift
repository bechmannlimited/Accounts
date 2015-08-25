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
    
    func splitTheBill(inout ignoreIdList: Dictionary<String, String?>, givePriorityTo: String?) { //, editingTransaction: Transaction?) {
        println(ignoreIdList)
        var debug: () -> () = {
            
            var totalCheck:Double = 0
            
            for transaction in self.transactions {
                
                totalCheck += transaction.amount
            }
            
            if totalCheck != self.amount {
                
                println("ERRORRORRR")
            }
        }
        
        var didComplete = false
        
        if ignoreIdList.count < self.transactions.count && ignoreIdList.count > 0 { // attempt 1
            
            var ignoredTransactionAmounts: Double = self.amount
            
            let transactionsInIgnoreList = self.transactions.filter({ (t) -> Bool in
                
                var rc = false
                
                if let toUser = t.toUser {
                    
                    rc = ignoreIdList[toUser.objectId!] != nil
                }
                
                return rc
            })
            
            if let priorityTransaction = transactionForToUserId(givePriorityTo) {
                
                priorityTransaction.amount = priorityTransaction.amount <= self.amount ? priorityTransaction.amount : self.amount
                
                for transaction in transactionsInIgnoreList {
                    
                    if priorityTransaction.amount + transaction.amount > self.amount {
                        
                        transaction.amount = 0
                        ignoreIdList.removeValueForKey(transaction.toUser!.objectId!)
                    }
                    else {
                        
                        ignoredTransactionAmounts += transaction.amount
                    }
                }
            }
            
            let transactionsNotInIgnoreList = self.transactions.filter({ (t) -> Bool in
                
                var rc = false
                
                if let toUser = t.toUser {
                    
                    rc = ignoreIdList[toUser.objectId!] == nil
                }
                
                return rc
            })
            
            var splitAmount = ignoredTransactionAmounts / Double(transactionsNotInIgnoreList.count)
            
            for transaction in transactionsNotInIgnoreList {

                transaction.amount = splitAmount > 0 ? splitAmount : 0
                ignoreIdList.removeValueForKey(transaction.toUser!.objectId!)
                
                println("a")
                didComplete = true
            }
        }
        
        if didComplete { debug(); return }
        
        if let id = givePriorityTo { // attempt 2

            ignoreIdList.removeAll(keepCapacity: false)
            
            if let transaction = transactionForToUserId(id) {
 
                transaction.amount = transaction.amount <= self.amount ? transaction.amount : self.amount
                
                let transactions = self.transactions.filter({ (t) -> Bool in
                    
                    return t.toUser?.objectId != id
                })
                
                var splitAmount = (self.amount - transaction.amount) / Double(transactions.count)
                
                for transaction in transactions {
                    
                    transaction.amount = splitAmount > 0 ? splitAmount : 0
                    //ignoreIdList.removeValueForKey(transaction.toUser!.objectId!)
                }
                
                didComplete = true
            }
        }

        if didComplete { debug(); return }
        
        
        //attempt 3
        let splitAmount = self.amount / Double(self.transactions.count)
        
        for transaction in transactions {
            
            transaction.amount = splitAmount
        }
        
        ignoreIdList.removeAll(keepCapacity: false)
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

    
    func calculateTotalFromTransactions() {
        
        amount = 0
        
        for transaction in transactions {
            
            amount += transaction.amount
        }
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