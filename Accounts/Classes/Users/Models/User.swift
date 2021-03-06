//
//  User.swift
//  Accounts
//
//  Created by Alex Bechmann on 08/04/2015.
//  Copyright (c) 2015 Ustwo. All rights reserved.
//

import UIKit
 
import SwiftyJSON
import Alamofire
import Parse
import FBSDKCoreKit
import SwiftOverlays

enum UserType : NSNumber {
    
    case FreeUser = 0
    case ProUser = 5
}

class User: PFUser {
    
    //var friends = [User]()
    var friends: [User] = []
    //var localeDifferenceBetweenActiveUser:Double = 0
    
    //for a friend to see what they owe the active user
    var differencesBetweenActiveUser: Dictionary<String, NSNumber> = Dictionary<String, NSNumber>()
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
    //@NSManaged var friendsIdsWithDifference: Dictionary<String, NSNumber>?
    
    // for current user to log what all friends owe
    @NSManaged var friendsIdsWithDifferenceWithMultipleCurrencies: Dictionary<String, Dictionary<String, NSNumber>>?
    @NSManaged var userType: NSNumber?
    @NSManaged var lastSyncedDataInfo: Dictionary<String, NSDate>?
    @NSManaged var preferredCurrencyId: NSNumber?
    
    var facebookFriendIds = Array<String>()
    
    var proSubscriptionDialogIsActive: Bool = false
    
    func modelIsValid() -> Bool {
        
        return username?.length() > 0 && password?.length() > 0 && email?.length() > 0 && password == passwordForVerification
    }
    
    func modelIsValidForLogin() -> Bool {
        
        return username?.length() > 0 && password?.length() > 0
    }
    
    func removeFriend(friend:User, completion: (success: Bool) -> ()) {
    
        let params: [NSObject : AnyObject] = [
            "fromUserId" : User.currentUser()!.objectId!,
            "toUserId": friend.objectId!,
            "friendRequestStatus" : FriendRequestStatus.RequestingDeletion.rawValue
        ]
        PFCloud.callFunctionInBackground("SaveFriendRequest", withParameters: params, block: { (response, error) -> Void in
            
            ParseUtilities.showAlertWithErrorIfExists(error)
         
            Task.sharedTasker().executeTaskInBackground({ () -> () in
                
                for f in self.friends.filter({ (t) -> Bool in
                    
                    return t.objectId == friend.objectId
                }) {
                    
                    self.friends.removeAtIndex(self.friends.indexOf(f)!)
                    self.relationForKey("friends").removeObject(f)
                }
                
                self.friendsIdsWithDifferenceWithMultipleCurrencies?.removeValueForKey(friend.objectId!)
                
                do {
                    
                    try friend.unpin()
                    try self.save()
                }
                catch {}
                
            }, completion: { () -> () in
                
                completion(success: true)
            })
        })
        
//        PFCloud.callFunctionInBackground("RemoveFriend", withParameters: [
//            "fromUserId" : objectId!,
//            "toUserId" : friend.objectId!
//        ]) { (response, error) -> Void in
//            
//            ParseUtilities.showAlertWithErrorIfExists(error)
//            
//            completion(success: error != nil)
//        }
    }
    
    func appropriateDisplayName() -> String {
        
        if objectId == User.currentUser()?.objectId {
            
            return "You"
        }
        else if let name = displayName {
            
            if name.isEmpty == false {
                
                return name
            }
        }
        else if let name = username {
            
            if name.isEmpty == false {
                
                return name
            }
        }
        
        return String.emptyIfNull(username)
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
        
        
        return appropriateDisplayName().componentsSeparatedByString(" ")
    }
    
    func namePrioritizingDisplayName() -> String {
        
        if displayName?.isEmpty == false {
            
            return displayName!
        }
        else if username?.isEmpty == false {
            
            return username!
        }
        
        return ""
    }
    
    func pendingInvitesCount() -> Int {
        
        var count = 0
        
        for list in allInvites {
            
            for invite in list {
                
                if invite.toUser?.objectId == objectId {
                    
                    count++
                }
            }
        }
        
        return count
    }
    
    func getFriends(completion:(completedRemoteRequest:Bool) -> ()) {

        let execRemoteQuery: () -> () = {
            
            if let _ = self.facebookId {
                
                let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: ["fields": "id"])
                graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                    
                    print("fbsdk get users me/friends error?: \(error)")
                    
                    if error == nil {
                        
                        var canContinue = true
                        
                        Task.sharedTasker().executeTaskInBackgroundWithIdentifier("GetFriends", task: { () -> Void in
                            
                            var friendInfo = Dictionary<String, Dictionary<String, NSNumber>>()
                            
                            var queries = [PFQuery]()
                            let query1 = User.currentUser()?.relationForKey(kParse_User_Friends_Key).query() // must add friends relation back to user
                            
                            //if let facebookId = self.facebookId {
                                
                                let friendsJson = JSON(result)["data"]
                                
                                for (_, friendJson): (String, JSON) in friendsJson {
                                    
                                    self.facebookFriendIds.append(friendJson["id"].stringValue)
                                    let friendQuery = User.query()
                                    friendQuery?.whereKey("facebookId", equalTo: friendJson["id"].stringValue)
                                    queries.append(friendQuery!)
                                }
                            //}
                            
                            if Settings.shouldShowTestBot() {
                                
                                let botQuery = User.query()
                                botQuery?.whereKey("objectId", equalTo: kTestBotObjectId)
                                queries.append(botQuery!)
                            }
                            
                            queries.append(query1!)  // must add friends relation back to user
                            
                            do {
                                
                                if let friends = try PFQuery.orQueryWithSubqueries(queries).orderByAscending("objectId").findObjects() as? [User] {
                                    
                                    self.friends = friends
                                }
                                
                                var friendIds = Array<String>()
                                
                                for friend in self.friends {
                                    
                                    try friend.fetch()
                                    friendIds.append(friend.objectId!)
                                }
                                
                                if let cloudResponse: AnyObject = try PFCloud.callFunction("DifferenceBetweenActiveUserFromUsersWithMultipleCurrencies", withParameters: ["ids": friendIds]) {
                                    
                                    let responseJson = JSON(cloudResponse)
                                    
                                    for (key,differenceJson):(String, JSON) in responseJson {
                                        
                                        for friend in self.friends {
                                            
                                            if friend.objectId == key {
                                                
                                                let results = Currency.CurrencyDifferencesFromCloudResponseWithStringKey(differenceJson)
                                                friendInfo[friend.objectId!] = results // NSNumber(double: differenceJson.doubleValue)
                                            }
                                        }
                                    }
                                }
                                else{
                                    
                                    canContinue = false
                                }
                                
                                if canContinue {
                                    
                                    try PFObject.pinAll(self.friends)
                                    
                                    self.friendsIdsWithDifferenceWithMultipleCurrencies = friendInfo
                                    self.pinInBackground()
                                    self.saveInBackground()
                                }
                            }
                            catch {}
                            
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
            
            else {
                
                var canContinue = true
                
                Task.sharedTasker().executeTaskInBackgroundWithIdentifier("GetFriends", task: { () -> Void in
                    
                    var friendInfo = Dictionary<String, Dictionary<String, NSNumber>>()
                    
                    var queries = [PFQuery]()
                    let query1 = User.currentUser()?.relationForKey(kParse_User_Friends_Key).query() // must add friends relation back to user
                    
                    if Settings.shouldShowTestBot() {
                        
                        let botQuery = User.query()
                        botQuery?.whereKey("objectId", equalTo: kTestBotObjectId)
                        queries.append(botQuery!)
                    }
                    
                    queries.append(query1!)  // must add friends relation back to user

                    do {
                        
                        if let friends = try PFQuery.orQueryWithSubqueries(queries).orderByAscending("objectId").findObjects() as? [User] {
                            
                            self.friends = friends
                        }
                        
                        var friendIds = Array<String>()
                        
                        for friend in self.friends {
                            
                            try friend.fetch()
                            friendIds.append(friend.objectId!)
                        }
                        
                        if let cloudResponse: AnyObject = try PFCloud.callFunction("DifferenceBetweenActiveUserFromUsersWithMultipleCurrencies", withParameters: ["ids": friendIds]) {
                            
                            let responseJson = JSON(cloudResponse)
                            
                            for (key,differenceJson):(String, JSON) in responseJson {
                                
                                for friend in self.friends {
                                    
                                    if friend.objectId == key {
                                        
                                        let results = Currency.CurrencyDifferencesFromCloudResponseWithStringKey(differenceJson)
                                        friendInfo[friend.objectId!] = results // NSNumber(double: differenceJson.doubleValue)
                                    }
                                }
                            }
                        }
                        else{
                            
                            canContinue = false
                        }
                        
                        if canContinue {
                            
                            try PFObject.pinAll(self.friends)
                            
                            self.friendsIdsWithDifferenceWithMultipleCurrencies = friendInfo
                            self.pinInBackground()
                            self.saveInBackground()
                        }
                    }
                    catch {}
                    
                }, completion: { () -> () in
                    
                    if canContinue {
                        
                        completion(completedRemoteRequest: true)
                    }
                })
            }

        }
        
        var ids = [String]()
        
        if let friendInfos = friendsIdsWithDifferenceWithMultipleCurrencies {
            
            for friend in friendInfos{
                
                if friend.0 != User.currentUser()?.objectId {
                    
                    ids.append(friend.0)
                }
            }
            
            let localQuery = User.query()?.whereKey("objectId", containedIn: ids).orderByAscending("objectId").fromLocalDatastore()
            
            if !Settings.shouldShowTestBot() {
                
                localQuery?.whereKey("objectId", notEqualTo: "soRCUYqg6W")
            }
            
            localQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if let friends = objects as? [User] {
                    
                    self.friends = friends
                    
                    for friend in self.friends {
                        
                        friend.differencesBetweenActiveUser = friendInfos[friend.objectId!]!
                        //friend.localeDifferenceBetweenActiveUser = Double(friendInfos[friend.objectId!]!)
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
        
        let friendRequest = FriendRequest()
        friendRequest.fromUser = User.currentUser()
        friendRequest.toUser = friend
        
        let params: [NSObject : AnyObject] = [
            "fromUserId" : friendRequest.fromUser!.objectId!,
            "toUserId": friendRequest.toUser!.objectId!,
            "friendRequestStatus" : FriendRequestStatus.Pending.rawValue
        ]
        
        PFCloud.callFunctionInBackground("SaveFriendRequest", withParameters: params) { (response, error) -> Void in
            
            ParseUtilities.showAlertWithErrorIfExists(error)
            
            completion(success: error == nil)
        }
    }
    
    func addFriendFromRequest(friendRequest: FriendRequest, completion:(success: Bool) -> ()) {
        
        let params: [NSObject : AnyObject] = [
            "fromUserId" : friendRequest.fromUser!.objectId!,
            "toUserId": friendRequest.toUser!.objectId!,
            "friendRequestStatus" : FriendRequestStatus.Confirmed.rawValue
        ]
        
        PFCloud.callFunctionInBackground("SaveFriendRequest", withParameters: params) { (response, error) -> Void in
                
            ParseUtilities.showAlertWithErrorIfExists(error)
            
            completion(success: error == nil)
        }
    }
    
    func getInvites(completion:(invites:Array<Array<FriendRequest>>) -> ()) {

        allInvites = [[],[]]
        var unconfirmedInvites = Array<FriendRequest>()
        var unconfirmedSentInvites = Array<FriendRequest>()
        
        if let currentUser = User.currentUser() {
            
            if currentUser.objectId == objectId {
                
                let query1 = FriendRequest.query()
                query1?.whereKey("fromUser", equalTo: currentUser)
                
                let query2 = FriendRequest.query()
                query2?.whereKey("toUser", equalTo: currentUser)
                
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
                    
                    self.allInvites = []
                    self.allInvites.append(unconfirmedInvites)
                    self.allInvites.append(unconfirmedSentInvites)
                    
                    if User.currentUser()?.objectId == self.objectId {
                        
                        completion(invites: self.allInvites)
                    }
                })
            }
        }
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
    
    // MARK: -  in app purchase
    
    func launchProSubscriptionDialogue (message: String, completion: () -> ()) {
        
        if User.isCurrentUser(self) {
            
            if User.currentUser()!.userType != UserType.ProUser.rawValue && !proSubscriptionDialogIsActive {
                
                proSubscriptionDialogIsActive = true
                
                UIAlertController.showAlertControllerWithButtonTitle("Get Pro", confirmBtnStyle: .Default, message: message, completion: { (response) -> () in
                    
                    if response == AlertResponse.Confirm {
                        
                        SwiftOverlays.showBlockingWaitOverlayWithText("Checking your subscription...")
                        
                        User.currentUser()?.fetchInBackgroundWithBlock({ (_, error) -> Void in
                            
                            SwiftOverlays.removeAllBlockingOverlays()
                            ParseUtilities.showAlertWithErrorIfExists(error)
                            
                            if User.currentUser()?.userType != UserType.ProUser.rawValue && error == nil {
                                
                                SwiftOverlays.showBlockingWaitOverlayWithText("Fetching subscription details...")
                                
                                self.getPro({ (success, error) -> () in
                                    
                                    SwiftOverlays.removeAllBlockingOverlays()
                                    
                                    print("yo \(success)")
                                    
                                    if !success {
                                        
                                        UIAlertController.showAlertControllerWithButtonTitle("Ok", confirmBtnStyle: .Default, message: "In app purchase failed", completion: { (response) -> () in
                                            
                                            completion()
                                        })
                                    }
                                    else {
                                        
                                        completion()
                                    }
                                    
                                    self.proSubscriptionDialogIsActive = false
                                })
                            }
                            else {
                                
                                if User.currentUser()?.userType == UserType.ProUser.rawValue {
                                    
                                    UIAlertController.showAlertControllerWithButtonTitle("Ok", confirmBtnStyle: .Default, message: "You are already a Pro user!", completion: { (response) -> () in
                                        
                                        completion()
                                    })
                                }
                                else{
                                    
                                    completion()
                                }
                                
                                self.proSubscriptionDialogIsActive = false
                            }
                        })
                    }
                    else {
                        
                        completion()
                        self.proSubscriptionDialogIsActive = false
                    }
                    
                })
            }
        }
    }
    
    func getPro(completion: (success: Bool, error: NSError?) -> ()) {
        
        PFPurchase.buyProduct(kProSubscriptionProductID, block: { (error: NSError?) -> Void in
            
            if let error = error {
                
                print(error)
                completion(success: false, error: error)
            }
            else {
                
                completion(success: true, error : error )
            }
        })
    }

    func urlForProfilePicture() -> String {
        
        var url = ""
        
        if let id = facebookId {
            
            url = "https://graph.facebook.com/\(id)/picture?width=\(500)&height=\(500)"
            
        }
        
        return url
    }
    
    func getProfilePicture(completion: (image: UIImage) -> ()) {
        
        if objectId != kTestBotObjectId {
            
            let url = urlForProfilePicture()
            
            ABImageLoader.sharedLoader().loadImageFromCacheThenNetwork(url, completion: { (image) -> () in
                
                completion(image: image)
            })
        }
        else {
            
            completion(image: AppTools.iconAssetNamed("50981152_thumbnail.jpg"))
        }
    }
    
    func descriptionForHowToAddAsFriend() -> String {
        
        var text = ""
        var namesAdded = 0
        
        if displayName?.isEmpty == false {
            
            text += "\"\(displayName!)\""
            namesAdded++
        }
        if username?.isEmpty == false && facebookId == nil {
            
            let connector = namesAdded == 0 ? "" : ", "
            text += "\(connector)\"\(username!)\""
        }
        
        let orYourEmail: String = email?.isEmpty == false ? " or your email" : ""
        text = "Your friends can find you by searching for \(text)\(orYourEmail) in the friend invites section. "
        
        if facebookId != nil {
            
            text += "Your Facebook friends who have this app, will appear in your friends list!"
        }

        return text
    }
}