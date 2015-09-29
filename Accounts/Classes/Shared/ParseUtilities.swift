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
    
    class func sendPushNotificationsInBackgroundToUsers(users: [User], message: String, data: [NSObject : AnyObject]?, iouEvent: IOUEvent) {
        
        let query = PFInstallation.query()
        var userIds:[String] = []
        
        for user in users{
            
            query?.whereKey("user", equalTo: user)
            userIds.append(user.objectId!)
        }
        
        userIds.append(User.currentUser()!.objectId!)
        
        var pushData: [NSObject : AnyObject] = data != nil ? data! : [NSObject : AnyObject]()
        
        let pushNotification = PFPush()
        pushNotification.setQuery(query)
        
        pushData["alert"] = message
        pushData["sound"] = "default"
        pushData["userIds"] = userIds
        pushData["iouEvent"] = iouEvent.rawValue
        pushData["message"] = message
            
        pushNotification.setData(pushData)
        pushNotification.sendPushInBackground()
    }
    
    class func convertPFObjectToDictionary(object: PFObject) -> Dictionary<String, AnyObject?> {
    
        var itemDictionary = Dictionary<String, AnyObject?>()
        
        var copy: PFObject = PFObject(withoutDataWithClassName: object.parseClassName, objectId: object.objectId)
        
        for key in object.allKeys() {
            
            itemDictionary[key as! String] = object.objectForKey(key as! String)
        }
        
        return itemDictionary
    }
//    
//    class func findObjectsInLocalAndRemoteDataStore(query: PFQuery?) -> BFTask? {
//        
//        return query?.findObjectsInBackground().continueWithBlock({ (task) -> AnyObject! in
//            
//            if let objects = task.result as? [PFObject] {
//                
//                return PFObject.pinAllInBackground(objects)
//            }
//        })
//        
//        query?.fromLocalDatastore()
//        
//        return query?.findObjectsInBackground().continueWithBlock({ (task) -> AnyObject! in
//            
//            if let objects = task.result as? [PFObject] {
//                
//                return PFObject.pinAllInBackground(objects)
//            }
//        })
//    }
//    
//    - (BFTask *)find:(PFQuery *)query {
//    return [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task) {
//        BFTask *(^pin)(void) = ^ {
//            return [[PFObject pinAllInBackground:task.result] continueWithExecutor:[BFExecutor mainThreadExecutor]
//            withSuccessBlock:^id(BFTask *task) {
//            return task.result;
//            }];
//    };
//    
//    [query fromLocalDatastore];
//    return [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
//    if (!task.error && [task.result count]) {
//    return [[PFObject unpinAllInBackground:task.result] continueWithBlock:^id(BFTask *task) {
//    return pin();
//    }];
//    } else {
//    return pin();
//    }
//    }];
//    }];
//    }
//    
}

public enum PushNotificationType: Int{
    
    case FriendRequestSent = 0
    case FriendRequestAccepted = 1
    case FriendRequestDeleted = 2
    case PurchaseSaved = 3
    case ItemSaved = 4
    case TransactionSaved = 5
}
