//
//  Transaction.swift
//  Accounts
//
//  Created by Alex Bechmann on 20/04/2015.
//  Copyright (c) 2015 Ustwo. All rights reserved.
//

import UIKit
 
import SwiftyJSON
import Alamofire
import Parse

enum TransactionType: NSNumber {
    
    case iou = 0
    case payment = 1
}

class Transaction: PFObject {
   
    @NSManaged var fromUser: User?
    @NSManaged var toUser: User?
    @NSManaged var amount: Double
    //@NSManaged var transactionDescription: String
    @NSManaged var title: String?
    @NSManaged var purchaseObjectId: String?
    @NSManaged var transactionDate: NSDate
    @NSManaged private var transactionType: NSNumber?
    @NSManaged var purchaseTransactionLinkUUID: String?
    @NSManaged var isDeleted: Bool
    @NSManaged var currencyId: NSNumber?
    @NSManaged var isSecure: Bool
    
    func currency() -> CurrencyEnum {
        
        return Currency.CurrencyFromNSNumber(currencyId)
    }
    
    var purchase: Purchase?
    
    var type: TransactionType {
        
        get{
            
            if let transactionType = transactionType {

                if let t = TransactionType(rawValue: transactionType) {

                    return t
                }
            }
            
            return TransactionType.iou
        }
        set {
            
            transactionType = newValue.rawValue
        }
    }
    
    var localeAmount: Double {
        
        get {
            
//            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
//            
//            if currencyIdentifier == "DKK" {
//                
//                return self.amount * 10
//            }
//            else {
//                
//                return self.amount
//            }
            return self.amount
        }
        
        set(newValue) {
            
//            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
//            
//            if currencyIdentifier == "DKK" {
//                
//                self.amount = newValue / 10
//            }
//            else {
//                
//                self.amount = newValue
//            }
            self.amount = newValue
        }
    }
    
    class func withDefaultValues() -> Transaction {
        
        let transaction = Transaction()
        
        transaction.fromUser = User.currentUser()
        transaction.transactionDate = NSDate()
        transaction.title = ""
        transaction.currencyId = Settings.defaultCurrencyId()
        
        return transaction
    }
    
    func modelIsValid() -> Bool {

        var errors:Array<String> = []

        if fromUser == nil {

            errors.append("User not set")
        }

        if toUser == nil {

            errors.append("This transaction isnt going to anyone!")
        }

        if amount == 0 {

            errors.append("The amount is 0")
        }

        if String.emptyIfNull(title) == "" {

            errors.append("title is empty")
        }

        var c = 1
        var errorMessageString = ""

        for error in errors {

            let suffix = c == errors.count ? "" : ", "
            errorMessageString += "\(error)\(suffix)"
            c++
        }

        if errors.count > 0 {
            
            //UIAlertView(title: "Transaction not saved!", message: errorMessageString, delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        return errors.count == 0
    }
        
    func pushNotificationTargets() -> [User]{
    
        var targets = [User]()
        
        for user in [self.fromUser!, self.toUser!] {
            
            if user.objectId != User.currentUser()?.objectId{
                
                targets.append(user)
            }
        }
        
        return targets
    }
    
//    func hardUnpin() {
//        
//        
//        
//        Task.executeTaskInBackground({ () -> () in
//            
//            self.unpinInBackground()
//            self.purchase?.unpin()
//            self.fromUser?.unpin()
//            self.toUser?.unpin()
//            PFObject.unpinAll(self.purchase?.transactions)
//            self.purchase?.user.unpin()
//            
//        }, completion: { () -> () in
//            
//            
//        })
//    }
    
    func copyWithUsefulValues() -> Transaction {
        
        let transaction = Transaction()
        
        transaction.fromUser = fromUser
        transaction.toUser = toUser
        transaction.amount = amount
        transaction.title = title
        transaction.transactionDate = transactionDate
        transaction.purchase = purchase
        transaction.type = type
        transaction.purchaseTransactionLinkUUID = purchaseTransactionLinkUUID
        transaction.isSecure = isSecure
        transaction.currencyId = currencyId
        
        return transaction
    }
    
    func setUsefulValuesFromCopy(transaction: Transaction) {
        
        fromUser = transaction.fromUser
        toUser = transaction.toUser
        amount = transaction.amount
        title = transaction.title
        transactionDate = transaction.transactionDate
        purchase = transaction.purchase
        isSecure = transaction.isSecure
        currencyId = transaction.currencyId
    }
    
    class func calculateOfflineOweValuesWithTransaction(transaction: Transaction?){
        
        if let transaction = transaction {
            
            if let cId = transaction.currencyId {
                
                let currencyId = "\(cId)"
                
                if transaction.fromUser?.objectId == User.currentUser()?.objectId  {
                    
                    let differences = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.toUser!.objectId!]
                    
                    if differences != nil && differences!.keys.contains(currencyId) {
                        
                        var amount = JSON(transaction.toUser!.differencesBetweenActiveUser[currencyId]!).doubleValue
                        amount += transaction.amount
                        transaction.toUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.toUser!.objectId!] = transaction.toUser!.differencesBetweenActiveUser
                    }
                    else {
                        
                        let amount = transaction.amount
                        transaction.toUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.toUser!.objectId!] = transaction.toUser!.differencesBetweenActiveUser
                    }
                    
                    if User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.toUser!.objectId!]?[currencyId] == 0 {
                        
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.toUser!.objectId!]?.removeValueForKey(currencyId)
                    }
                }
                else if transaction.toUser?.objectId == User.currentUser()?.objectId  {
                    
                    let differences = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.fromUser!.objectId!]
                    
                    if differences != nil && differences!.keys.contains(currencyId) {
                        
                        let differences = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.fromUser!.objectId!]
                        var amount = Double(differences![currencyId]!)
                        //var amount = JSON(transaction.fromUser!.differencesBetweenActiveUser[currencyId]!).doubleValue
                        amount -= transaction.amount
                        transaction.fromUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.fromUser!.objectId!] = transaction.fromUser!.differencesBetweenActiveUser
                    }
                    else {
                        
                        let amount = -transaction.amount
                        transaction.fromUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.fromUser!.objectId!] = transaction.fromUser!.differencesBetweenActiveUser
                    }
                    
                    if User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.fromUser!.objectId!]?[currencyId] == 0 {
                        
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.fromUser!.objectId!]?.removeValueForKey(currencyId)
                    }
                }
            }
        }
    }
    
    class func calculateOfflineOweValuesByDeletingTransaction(transaction: Transaction?){
        //TODO: Remove key if value is 0
        if let transaction = transaction {
            
            if let cId = transaction.currencyId {
                
                let currencyId = "\(cId)"
                    
                if transaction.fromUser?.objectId == User.currentUser()?.objectId  {
                    
                    let differences = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.toUser!.objectId!]
                    
                    if differences != nil && differences!.keys.contains(currencyId) {
                        
                        var amount = Double(differences![currencyId]!)
                        //var amount = JSON(transaction.toUser!.differencesBetweenActiveUser[currencyId]!).doubleValue
                        amount -= transaction.amount
                        transaction.toUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.toUser!.objectId!] = transaction.toUser!.differencesBetweenActiveUser
                    }
                    else {
                        
                        let amount = -transaction.amount
                        transaction.toUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.toUser!.objectId!] = transaction.toUser!.differencesBetweenActiveUser
                    }
                    
                    if User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.toUser!.objectId!]?[currencyId] == 0 {
    
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.toUser!.objectId!]?.removeValueForKey(currencyId)
                    }
                }
                else if transaction.toUser?.objectId == User.currentUser()?.objectId  {
                    
                    let differences = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.fromUser!.objectId!]
                    
                    if differences != nil && differences!.keys.contains(currencyId) {
                        
                        var amount = Double(differences![currencyId]!)
                        //var amount = JSON(transaction.toUser!.differencesBetweenActiveUser[currencyId]!).doubleValue
                        amount += transaction.amount
                        transaction.fromUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.fromUser!.objectId!] = transaction.fromUser!.differencesBetweenActiveUser
                    }
                    else {
                        
                        let amount = transaction.amount
                        transaction.fromUser?.differencesBetweenActiveUser[currencyId] = NSNumber(double: amount)
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies![transaction.fromUser!.objectId!] = transaction.fromUser!.differencesBetweenActiveUser
                    }
                    
                    if User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.fromUser!.objectId!]?[currencyId] == 0 {
                        
                        User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[transaction.fromUser!.objectId!]?.removeValueForKey(currencyId)
                    }
                }
                
            }
        }
    }
    
    private func getPurchaseInfoFromLocalDatastore(completion:(total: Double, error: String?) -> ()) {
        
        if let uuid = purchaseTransactionLinkUUID {
            
            self.purchaseInfoQuery(uuid)?.fromLocalDatastore().findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                var total: Double = 0
                var transactionsCount = 0
                
                if let transactions = objects as? [Transaction] {
                    
                    for transaction in transactions {
                        
                        total += transaction.amount
                    }
                    
                    transactionsCount = transactions.count
                }

                if transactionsCount > 1 {
                    
                    completion(total: total, error: nil)
                }
                else {
                    
                    completion(total: total, error: "TransactionCount is not more than 1")
                }
            })
        }
    }
    
    private func purchaseInfoQuery(uuid: String) -> PFQuery? {
        
        return Transaction.query()?.whereKey("purchaseTransactionLinkUUID", equalTo: uuid)
    }
    
    func getPurchaseInfo(completion:(total: Double, error: String?) -> ()) {

        if let uuid = purchaseTransactionLinkUUID {

            self.purchaseInfoQuery(uuid)?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                var total: Double = 0
                
                if let transactions = objects as? [Transaction] {
                    
                    for transaction in transactions {
                        
                        total += transaction.amount
                    }
                    
                    completion(total: total, error: nil)
                }
                
                else {
                    
                    completion(total: total, error: "Load failed")
                }
            })
            
//            getPurchaseInfoFromLocalDatastore({ (total, error) -> () in
// 
//                if error == nil {
//                    
//                    completion(total: total, error: error)
//                }
//                
//                self.purchaseInfoQuery(uuid)?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
//                    
//                    if let transactions = objects as? [Transaction] {
//                        
//                        Task.sharedTasker().executeTaskInBackground({ () -> () in
//                            
//                            PFObject.unpinAll(self.purchaseInfoQuery(uuid)?.fromLocalDatastore().findObjects())
//                            PFObject.pinAll(objects)
//                            
//                        }, completion: { () -> () in
//                            
//                            self.getPurchaseInfoFromLocalDatastore(completion)
//                        })
//                    }
//                })
//            })
        }
    }
}

extension Transaction: PFSubclassing {
    
    static func parseClassName() -> String {
        return Transaction.getClassName()
    }
}
