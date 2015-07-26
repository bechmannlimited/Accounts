//
//  ParseUtilities.swift
//  Accounts
//
//  Created by Alex Bechmann on 13/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import Parse
import SwiftyJSON

let kPushNotificationTypeKey = "PushNotificationType"

public class ParseUtilities: NSObject {
    
    public class func showAlertWithErrorIfExists(error: NSError?) {
        
        if let err = error?.localizedDescription {
        
            UIAlertView(title: "Error!", message: err, delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    public class func performQueryLocallyAndRemotely(query: PFQuery?) {
        
        
    }
    
    class func sendPushNotificationsInBackgroundToUsers(users: [User], message: String, data: [NSObject : AnyObject]?) {
        
        let query = PFInstallation.query()
        var userIds:[String] = []
        
        for user in users{
            
            query?.whereKey("user", equalTo: user)
            userIds.append(user.objectId!)
        }
        
        userIds.append(User.currentUser()!.objectId!)
        
        var pushData: [NSObject : AnyObject] = data != nil ? data! : [NSObject : AnyObject]()
        
        var pushNotification = PFPush()
        pushNotification.setQuery(query)
        
        pushData["alert"] = message
        pushData["sound"] = "default"
        pushData["userIds"] = userIds
            
        pushNotification.setData(pushData)
        pushNotification.sendPushInBackground()
    }
    
}

public enum PushNotificationType: Int{
    
    case FriendRequestSent = 0
    case FriendRequestAccepted = 1
    case FriendRequestDeleted = 2
    case PurchaseSaved = 3
    case ItemSaved = 4
    case TransactionSaved = 5
}
