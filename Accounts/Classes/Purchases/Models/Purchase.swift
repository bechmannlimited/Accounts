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

    @NSManaged var amount: Double
    //@NSManaged var purchaseDescription: String?
    @NSManaged var title: String
    @NSManaged var user: User
    @NSManaged var purchasedDate:NSDate?
    
    @NSManaged var transactions: Array<Transaction>
    //var friends: [User] = []
    //var billSplitDictionary = Dictionary<User, Double>()
    
    var originalTransactions = Array<Transaction>()
    
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
    
    func savePurchase(completion: (success:Bool) -> ()) {
        
        var isNewPurchase = objectId == nil
        
        if !modelIsValid() {

            completion(success: false)
        }
        
        var sendPushNotifications: () -> () = {
            
            var pushNotificationTargets = [User]()
            
            for transaction in self.transactions {
                
                if transaction.toUser != User.currentUser() {
                    
                    pushNotificationTargets.append(transaction.toUser!)
                }
            }
            
            let noun: String = isNewPurchase ? "added" : "updated"
            let message = "Purchase: \(self.title) \(noun)!"
            
            ParseUtilities.sendPushNotificationsInBackgroundToUsers(pushNotificationTargets, message: message)
        }
        
        for transaction in transactions {
            
            transaction.purchaseObjectId = objectId
            transaction.transactionDate = purchasedDate!
            transaction.title = title
        }
        
        PFObject.saveAllInBackground(transactions, block: { (success, error) -> Void in
            
            if success {
                
                // now save the purchase itself
                self.saveInBackgroundWithBlock({ (success, error) -> Void in

                    if success{
                        
                        sendPushNotifications()
                    }
                    else{
                        
                        ParseUtilities.showAlertWithErrorIfExists(error)
                    }
                    
                    completion(success: success)
                })
            }
            else {
                
                ParseUtilities.showAlertWithErrorIfExists(error)
                completion(success: false)
            }
        })
    }
    
    func splitTheBill() {
        
        let splitAmount = self.amount / Double(self.transactions.count)
        
        for transaction in transactions {
            
            transaction.amount = splitAmount
        }
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
    
    func usersInTransactions() -> Array<User> {
        
        var users = Array<User>()
        
        for transaction in transactions {
            
            users.append(transaction.toUser!)
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
    
    func deletePurchaseAndTransactions(completion:() -> ()) {
        
        relationForKey("transactions").query()?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
            
            if let transactions = objects as? [Transaction] {// needed?
                
                PFObject.deleteAllInBackground(objects, block: { (success, error) -> Void in
                    
                    if success{
                        
                        self.deleteInBackgroundWithBlock({ (success, error) -> Void in
                            
                            completion()
                            ParseUtilities.showAlertWithErrorIfExists(error)
                        })
                    }
                    
                    ParseUtilities.showAlertWithErrorIfExists(error)
                })
            }
        })
    }
}

extension Purchase: PFSubclassing {
    
    static func parseClassName() -> String {
        return Purchase.getClassName()
    }
}