//
//  User.swift
//  Accounts
//
//  Created by Alex Bechmann on 08/04/2015.
//  Copyright (c) 2015 Ustwo. All rights reserved.
//

import UIKit
import ABToolKit
import SwiftyJSON
import Alamofire
import Parse
import FBSDKCoreKit

class User: PFUser {
    
    //var friends = [User]()
    var friends: [User] = []
    var localeDifferenceBetweenActiveUser:Double = 0
    var allInvites = [[FriendRequest]]()
    var passwordForVerification = ""
    
    var firstName: String {
        get{
        
            let pieces = appropriateDisplayNamesAsArray()
            if pieces.count > 0 {
                
                return pieces[0]
            }
            else{
                
                return appropriateDisplayName()
            }
        }
    }
    
    @NSManaged var facebookId: String?
    @NSManaged var displayName: String?
    @NSManaged var friendsIdsWithDifference: Dictionary<String, NSNumber>?
    
    @NSManaged var lastSyncedDataInfo: Dictionary<String, NSDate>?
    
    func modelIsValid() -> Bool {
        
        return username?.length() > 0 && password?.length() > 0 && email?.length() > 0 && password == passwordForVerification
    }
    
    func modelIsValidForLogin() -> Bool {
        
        return username?.length() > 0 && password?.length() > 0
    }
    
    func removeFriend(friend:User, completion: (success: Bool) -> ()) {
    
        let friendRequest = FriendRequest()
        friendRequest.fromUser = User.currentUser()
        friendRequest.toUser = friend
        friendRequest.friendRequestStatus = FriendRequestStatus.RequestingDeletion.rawValue
        
        friend.unpinInBackground()
        
        friendRequest.saveInBackgroundWithBlock { (success, error) -> Void in
            
            completion(success: success)
        }
    }
    
    func appropriateDisplayName() -> String {
    
        var rc = ""
        
        if objectId == User.currentUser()?.objectId {
            
            rc = "You"
        }
        else if let name = displayName {
            
            rc = name
        }
        else {
            
            rc = String.emptyIfNull(username)
        }
        
        return rc
    }
    
//    func imageUrl() -> String? {
//        
//        if objectId == "soRCUYqg6W" {
//            
//            return "bender.jpg"
//        }
//        else if let id = facebookId{
//            
//            return "https://graph.facebook.com/\(id)/picture?width=\(500)&height=\(500)"
//        }
//        
//        return nil
//    }
    
    func appropriateShortDisplayName() -> String {
        
        let name = appropriateDisplayName()
        
        if objectId == User.currentUser()?.objectId {
         
            return name
        }
        
        let names = appropriateDisplayNamesAsArray()
        
        var secondName: String = ""
        
        if names.count > 1 {
            
            secondName = String.emptyIfNull(names[1])
        }
        
        var requiresExtraInfo = false
        
        for friend in friends {
            
            for f in friends {
                
                if f.firstName == friend.firstName {
                    
                    requiresExtraInfo = true
                }
            }
        }
        
        if requiresExtraInfo {
            
            if secondName.length() >= 1 {
                
                return "\(firstName) \(String.emptyIfNull(secondName[0]))"
            }
        }
        
        return firstName
    }
    
    func appropriateDisplayNamesAsArray() -> [String] {
        
        return split(appropriateDisplayName()) {$0 == " "}
    }
    
    func getFriends(completion:(completedRemoteRequest:Bool) -> ()) {

        let execRemoteQuery: () -> () = {
            
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: nil)
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                
                println("error: \(error?.code)")
                
                if error == nil{
                    
                    var canContinue = true
                    
                    Task.executeTaskInBackground({ () -> () in
                        
//                        User.currentUser()?.relationForKey(kParse_User_Friends_Key).addObject(User.query()!.getObjectWithId("dtQy9phAlR")!)
//                        User.currentUser()?.save()
                        
                        var friendInfo = Dictionary<String, NSNumber>()
                        
                        var queries = [PFQuery]()
                        var query1 = User.currentUser()?.relationForKey(kParse_User_Friends_Key).query() // must add friends relation back to user
                        
                        if let facebookId = self.facebookId {
                            
                            let friendsJson = JSON(result)["data"]
                            
                            for (index: String, friendJson: JSON) in friendsJson {
                                
                                let friendQuery = User.query()
                                friendQuery?.whereKey("facebookId", equalTo: friendJson["id"].stringValue)
                                queries.append(friendQuery!)
                            }
                        }
                        
                        if Settings.shouldShowTestBot() {
                            
                            let botQuery = User.query()
                            botQuery?.whereKey("objectId", equalTo: kTestBotObjectId)
                            queries.append(botQuery!)
                        }
                        
                        queries.append(query1!)  // must add friends relation back to user
                        
                        self.friends = PFQuery.orQueryWithSubqueries(queries).orderByAscending("objectId").findObjects() as! [User]
                        
                        for friend in self.friends {
                            
                            if let cloudResponse: AnyObject = PFCloud.callFunction("DifferenceBetweenActiveUser", withParameters: ["compareUserId": friend.objectId!]) {
                                
                                let responseJson = JSON(cloudResponse)
                                friend.localeDifferenceBetweenActiveUser = responseJson.doubleValue
                                friendInfo[friend.objectId!] = NSNumber(double: responseJson.doubleValue)
                            }
                            else {
                                
                                canContinue = false
                            }
                        }
                        
                        if canContinue {
                            
                            PFObject.pinAll(self.friends)
                            
                            self.friendsIdsWithDifference = friendInfo
                            self.pinInBackground()
                            self.saveInBackground()
                        }
                        
                    }, completion: { () -> () in
                        
                        if canContinue {
                            
                            completion(completedRemoteRequest: true)
                        }
                    })
                }
                else{
                    
                    connection.cancel()
                }
            })
        }
        
        var ids = [String]()
        
        if let friendInfos = friendsIdsWithDifference{
            
            for friend in friendInfos{
                
                ids.append(friend.0)
            }
            
            let localQuery = User.query()?.whereKey("objectId", containedIn: ids).orderByAscending("objectId").fromLocalDatastore()
            
            if !Settings.shouldShowTestBot() {
                
                localQuery?.whereKey("objectId", notEqualTo: "soRCUYqg6W")
            }
            
            localQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if let friends = objects as? [User] {
                    
                    self.friends = friends
                    
                    for friend in self.friends {
                        
                        friend.localeDifferenceBetweenActiveUser = Double(friendInfos[friend.objectId!]!)
                    }
                    
                    completion(completedRemoteRequest: false)
                    execRemoteQuery()
                }
            })
        }
        else {
            
            completion(completedRemoteRequest: false)
            execRemoteQuery()
        }

    }
    
    func sendFriendRequest(friend:User, completion:(success:Bool) -> ()) {
        
        Task.executeTaskInBackground({ () -> () in
            
            let friendRequest = FriendRequest()
            friendRequest.fromUser = User.currentUser()
            friendRequest.toUser = friend
            
            //check to see if they accepted it meanwhile
            let query = FriendRequest.query()
            query?.whereKey("fromUser", equalTo: friendRequest.toUser!)
            query?.whereKey("toUser", equalTo: friendRequest.fromUser!)
            
            var acceptedFriendRequest = false
            
            if let match = query?.findObjects()?.first as? FriendRequest {
                
                if match.friendRequestStatus == FriendRequestStatus.Pending.rawValue {
                    
                    match.friendRequestStatus = FriendRequestStatus.Confirmed.rawValue
                    PFObject.saveAllInBackground([[match, User.currentUser()!]])
                    acceptedFriendRequest = true
                    
                    ParseUtilities.sendPushNotificationsInBackgroundToUsers([friend], message: "Friend request accepted by \(User.currentUser()!.appropriateDisplayName())", data: [kPushNotificationTypeKey : PushNotificationType.FriendRequestAccepted.rawValue])
                }
            }

            if !acceptedFriendRequest {
                
                friendRequest.friendRequestStatus = FriendRequestStatus.Pending.rawValue
                friendRequest.save()
                
                ParseUtilities.sendPushNotificationsInBackgroundToUsers([friend], message: "New friend request from \(User.currentUser()!.appropriateDisplayName())", data: [kPushNotificationTypeKey : PushNotificationType.FriendRequestSent.rawValue])
            }

        }, completion: { () -> () in
            
            completion(success:true)
        })
    }
    
    func addFriendFromRequest(friendRequest: FriendRequest, completion:(success: Bool) -> ()) {
        
        friendRequest.friendRequestStatus = FriendRequestStatus.Confirmed.rawValue
        
        PFObject.saveAllInBackground([friendRequest, User.currentUser()!], block: { (success, error) -> Void in
            
            completion(success: success)
            
            ParseUtilities.sendPushNotificationsInBackgroundToUsers([friendRequest.fromUser!], message: "Friend request accepted by \(User.currentUser()!.appropriateDisplayName())", data: [kPushNotificationTypeKey : PushNotificationType.FriendRequestAccepted.rawValue])
        })
    }
    
    func getInvites(completion:(invites:Array<Array<FriendRequest>>) -> ()) {

        allInvites = Array<Array<FriendRequest>>()
        var unconfirmedInvites = Array<FriendRequest>()
        var unconfirmedSentInvites = Array<FriendRequest>()
        
        let query1 = FriendRequest.query()
        query1?.whereKey("fromUser", equalTo: User.currentUser()!)
        
        let query2 = FriendRequest.query()
        query2?.whereKey("toUser", equalTo: User.currentUser()!)
        
        let query = PFQuery.orQueryWithSubqueries([query1!, query2!])
        query.includeKey(kParse_FriendRequest_fromUser_Key)
        query.includeKey(kParse_FriendRequest_toUser_Key)
        query.whereKey(kParse_FriendRequest_friendRequestStatus_Key, notEqualTo: FriendRequestStatus.Confirmed.rawValue)
        
        query.findObjectsInBackgroundWithBlock({ (friendRequests, error) -> Void in
            
            if let requests = friendRequests as? [FriendRequest] {
                
                for friendRequest in requests {
                    
                    if friendRequest.fromUser?.objectId == self.objectId {
                        
                        unconfirmedSentInvites.append(friendRequest)
                    }
                    else {
                        
                        unconfirmedInvites.append(friendRequest)
                    }
                }
            }
            
            self.allInvites.append(unconfirmedInvites)
            self.allInvites.append(unconfirmedSentInvites)
            
            completion(invites: self.allInvites)
        })
    }
    
    class func userListExcludingID(id: String?) -> Array<User> {

        var usersToChooseFrom = [User]()
        var allUsersInContext = [User]()

        for friend in User.currentUser()!.friends {

            allUsersInContext.append(friend)
        }
        allUsersInContext.append(User.currentUser()!)

        for user in allUsersInContext {

            if let excludeID = id {

                if user.objectId != excludeID {

                    usersToChooseFrom.append(user)
                }
            }
            else {

                usersToChooseFrom.append(user)
            }
        }

        return usersToChooseFrom
    }
    
    class func isCurrentUser(user: User?) -> Bool {
        
        return user?.objectId == User.currentUser()?.objectId
    }

}