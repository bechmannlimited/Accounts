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
    
    var friends = [User]()
    var localeDifferenceBetweenActiveUser:Double = 0
    var allInvites = [[FriendRequest]]()
    var passwordForVerification = ""
    
    @NSManaged var facebookId: String?
    @NSManaged var displayName: String?
    
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
        
        if let name = displayName {
            
            rc = name
        }
        else {
            
            rc = String.emptyIfNull(username)
        }
        
        return rc
    }
    
    func getFriends(completion:() -> ()) {

        friends = [User]()
        
        let execRemoteQuery: () -> () = {
            
            for friend in self.friends {
                
                friend.unpinInBackground()
            }
            
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: nil)
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                
                Task.executeTaskInBackground({ () -> () in
                    
                    var queries = [PFQuery]()
                    var query1 = User.currentUser()?.relationForKey(kParse_User_Friends_Key).query()
                    
                    if self.facebookId != nil {
                        
                        let friendsJson = JSON(result)["data"]
                        
                        for (index: String, friendJson: JSON) in friendsJson {
                            
                            let friendQuery = User.query()
                            friendQuery?.whereKey("facebookId", equalTo: friendJson["id"].stringValue)
                            queries.append(friendQuery!)
                        }
                    }
                    
                    queries.append(query1!)
                    
                    self.friends = PFQuery.orQueryWithSubqueries(queries).findObjects() as! [User]
                    
                    for friend in self.friends{
                        
                        let responseJson: JSON = JSON(PFCloud.callFunction("DifferenceBetweenActiveUser", withParameters: ["compareUserId": friend.objectId!])!)
                        friend.localeDifferenceBetweenActiveUser = responseJson.doubleValue
                        friend.pinInBackground()
                    }
                    
                    self.pinInBackground()
                    
                }, completion: { () -> () in
                        
                    completion()
                })
            })
        }
        
        execRemoteQuery()
        
//        let localQuery = relationForKey(kParse_User_Friends_Key).query()?.fromLocalDatastore()
//        
//        localQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
//            
//            if let friends = objects as? [User] {
//                println(friends);println("hi")
//                self.friends = friends
//                completion()
//                
//                execRemoteQuery()
//            }
//        })
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
}