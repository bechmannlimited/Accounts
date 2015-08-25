//
//  Transaction.swift
//  Accounts
//
//  Created by Alex Bechmann on 20/04/2015.
//  Copyright (c) 2015 Ustwo. All rights reserved.
//

import UIKit
import ABToolKit
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
    
    class func withDefaultValues() -> Transaction{
        
        var transaction = Transaction()
        
        transaction.fromUser = User.currentUser()
        transaction.transactionDate = NSDate()
        transaction.title = ""
        
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
    
    func hardUnpin() {
        
        Task.executeTaskInBackground({ () -> () in
            
            self.unpinInBackground()
            self.purchase?.unpin()
            self.fromUser?.unpin()
            self.toUser?.unpin()
            PFObject.unpinAll(self.purchase?.transactions)
            self.purchase?.user.unpin()
            
        }, completion: { () -> () in
            
            
        })
    }
    
    func copyWithUsefulValues() -> Transaction {
        
        var transaction = Transaction()
        
        transaction.fromUser = fromUser
        transaction.toUser = toUser
        transaction.amount = amount
        transaction.title = title
        transaction.transactionDate = transactionDate
        transaction.purchase = purchase
        transaction.type = type
        transaction.purchaseTransactionLinkUUID = purchaseTransactionLinkUUID
        
        return transaction
    }
    
    func setUsefulValuesFromCopy(transaction: Transaction) {
        
        fromUser = transaction.fromUser
        toUser = transaction.toUser
        amount = transaction.amount
        title = transaction.title
        transactionDate = transaction.transactionDate
        purchase = transaction.purchase
    }
    
    class func calculateOfflineOweValuesWithTransaction(transaction: Transaction?){
        
        if let transaction = transaction {
            
            if transaction.fromUser?.objectId == User.currentUser()?.objectId  {
                
                transaction.toUser?.localeDifferenceBetweenActiveUser += transaction.amount
                User.currentUser()?.friendsIdsWithDifference?[transaction.toUser!.objectId!] = NSNumber(double: transaction.toUser!.localeDifferenceBetweenActiveUser)
            }
            else if transaction.toUser?.objectId == User.currentUser()?.objectId  {
                
                transaction.fromUser?.localeDifferenceBetweenActiveUser -= transaction.amount
                User.currentUser()?.friendsIdsWithDifference?[transaction.fromUser!.objectId!] = NSNumber(double: transaction.fromUser!.localeDifferenceBetweenActiveUser)
            }
        }
    }
    
    class func calculateOfflineOweValuesByDeletingTransaction(transaction: Transaction?){
        
        if let transaction = transaction {
            
            if transaction.fromUser?.objectId == User.currentUser()?.objectId  {
                
                transaction.toUser?.localeDifferenceBetweenActiveUser -= transaction.amount
                User.currentUser()?.friendsIdsWithDifference?[transaction.toUser!.objectId!] = NSNumber(double: transaction.toUser!.localeDifferenceBetweenActiveUser)
            }
            else if transaction.toUser?.objectId == User.currentUser()?.objectId  {
                
                transaction.fromUser?.localeDifferenceBetweenActiveUser += transaction.amount
                User.currentUser()?.friendsIdsWithDifference?[transaction.fromUser!.objectId!] = NSNumber(double: transaction.fromUser!.localeDifferenceBetweenActiveUser)
            }
        }
    }
}

extension Transaction: PFSubclassing {
    
    static func parseClassName() -> String {
        return Transaction.getClassName()
    }
}
