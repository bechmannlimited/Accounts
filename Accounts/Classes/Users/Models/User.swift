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

class User: PFUser {
    
    var friends = [User]()
    var localeDifferenceBetweenActiveUser:Double = 0
    var allInvites = [[FriendRequest]]()
    
    @NSManaged var displayName: String?
    
    func modelIsValid() -> Bool {
        
        return username?.length() > 0 && password?.length() > 0 && email?.length() > 0
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
        
        User.currentUser()?.relationForKey(kParse_User_Friends_Key).query()?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in

            if let friends = objects as? [User] {
                
                User.currentUser()?.friends = objects as! [User]
                
                if let arr = objects as? [User] {
                    
                    self.friends = arr
                }
                
                let requiredRequestsCount = self.friends.count
                var completedRequests = 0
                
                for friend in self.friends{
                    
                    // get difference // needs a cloud code function instead
                    PFCloud.callFunctionInBackground("DifferenceBetweenActiveUser", withParameters: ["compareUserId": friend.objectId!]) { (response, error) -> Void in
                        
                        let responseJson = JSON(response!)
                        friend.localeDifferenceBetweenActiveUser = responseJson.doubleValue
                        
                        completedRequests++
                        
                        if completedRequests == requiredRequestsCount {
                            
                            completion()
                        }
                    }
                }
            }
        })
    }
    
    func sendFriendRequest(friend:User, completion:(success:Bool) -> ()) {
        
        let friendRequest = FriendRequest()
        friendRequest.fromUser = User.currentUser()
        friendRequest.toUser = friend
        friendRequest.friendRequestStatus = FriendRequestStatus.Pending.rawValue
        
        friendRequest.saveInBackgroundWithBlock { (success, error) -> Void in
            
            completion(success: success)
        }
    }
    
    func addFriendFromRequest(friendRequest: FriendRequest, completion:(success: Bool) -> ()) {
        
        friendRequest.friendRequestStatus = FriendRequestStatus.Confirmed.rawValue
        
        PFObject.saveAllInBackground([friendRequest, User.currentUser()!], block: { (success, error) -> Void in
            
            completion(success: success)
        })
    }
    
    func getInvites(completion:(invites:Array<Array<FriendRequest>>) -> ()) {

        allInvites = Array<Array<FriendRequest>>()
        var unconfirmedInvites = Array<FriendRequest>()
        var unconfirmedSentInvites = Array<FriendRequest>()
        
        let query = FriendRequest.query()
        query?.includeKey(kParse_FriendRequest_fromUser_Key)
        query?.includeKey(kParse_FriendRequest_toUser_Key)
        query?.whereKey(kParse_FriendRequest_friendRequestStatus_Key, notEqualTo: FriendRequestStatus.Confirmed.rawValue)
        
        query?.findObjectsInBackgroundWithBlock({ (friendRequests, error) -> Void in
            
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

//extension User: PFSubclassing {
//    
//    override class func parseClassName() -> String {
//        
//        return "User"
//    }
//}

//
//private let kActiveUserDefaultsKey = "activeUser"
//
//class User: JSONObject {
//    
//    var UserID = 0
//    var Username = ""
//    var Email = ""
//    var Password = ""
//    var friends: Array<User> = []
//    
//    //friend
//    //var relationStatusToActiveUser: RelationStatus = RelationStatus.Undefined
//    var DifferenceBetweenActiveUser: Double = 0
//    
//    var localeDifferenceBetweenActiveUser: Double {
//        
//        get {
//            
//            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
//            
//            if currencyIdentifier == "DKK" {
//                
//                return self.DifferenceBetweenActiveUser * 10
//            }
//            else {
//                
//                return self.DifferenceBetweenActiveUser
//            }
//        }
//        
//        set(newValue) {
//            
//            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
//            
//            if currencyIdentifier == "DKK" {
//                
//                self.DifferenceBetweenActiveUser = newValue / 10
//            }
//            else {
//                
//                self.DifferenceBetweenActiveUser = newValue
//            }
//        }
//    }
//    
//    //var transactions: Array<Transaction> = []
//    
////    override func setExtraPropertiesFromJSON(json:JSON)  {
////        
////        self.relationStatusToActiveUser = RelationStatus(rawValue: json["relationStatus"].intValue)!
////    }
//    
//    override func registerClassesForJsonMapping() {
//    
//        registerProperty("DifferenceBetweenActiveUser", withJsonKey: "Difference")
//        registerClass(User.self, forKey: "friends")
//    }
//    
//    
//    class func login(username: String, password: String) -> JsonRequest {
//        
//        return JsonRequest.create("http://alex.bechmann.co.uk/iou/api/Users/Login/?Username=\(username)&Password=\(password)", parameters: nil, method: .POST).onDownloadSuccessWithRequestInfo { (json, request, httpRequest, httpResponse) -> () in
//            
//            if httpResponse?.statusCode == 200 {
//                
//                var user: User = User.createObjectFromJson(json)
//                User.saveUserOnDevice(user as User?)
//                kActiveUser = user
//                
//                request.succeedContext()
//            }
//            else {
//                
//                request.failContext()
//            }
//        }
//    }
//    
//    func register() -> JsonRequest? {
//        
//        return webApiInsert()?.onDownloadSuccessWithRequestInfo({ (json, request, httpUrlRequest, httpUrlResponse) -> () in
//            
//            let statusCode = httpUrlResponse?.statusCode
//            
//            if statusCode == 201 {
//                
//                var user: User = User.createObjectFromJson(json)
//                User.saveUserOnDevice(user as User?)
//                kActiveUser = user
//                
//                request.succeedContext()
//            }
//            else{
//                
//                let errorsJson = json["ModelState"]["Error"]
//
//                let errors = NSMutableArray()
//
//                for (index: String, errorJson: JSON) in errorsJson {
//                    
//                    errors.addObject(errorJson.stringValue)
//                    println(errorJson)
//                }
//                
//                let errorMsg = errors.componentsJoinedByString(",\n")
//                
//                UIAlertView(title: "Error", message: errorMsg, delegate: nil, cancelButtonTitle: "OK").show()
//                
//                request.failContext()
//            }
//        })
//    }
//    
//    func logout() {
//        
//        User.saveUserOnDevice(nil)
//    }
//
//    
////    func getTransactionsLog(completion: (transactions: Array<Transaction>) -> ()) -> JsonRequest? {
////        
////        let url = "\(User.webApiUrls().getUrl(UserID))/Transactions"
////        
////        return JsonRequest.create(url, parameters: ["userID" : UserID], method: .GET).onDownloadSuccess({ (json, request) -> () in
////            
////            completion(transactions: Transaction.convertJsonToMultipleObjects(Transaction.self, json: json))
////        })
////    }
//    
//    func getFriends() -> JsonRequest {
//        
//        let s: String = User.webApiUrls().getUrl(UserID)!
//        
//        let url = "\(s)/Friends"
//
//        return JsonRequest.create(url, parameters: nil, method: .GET).onDownloadSuccess({ (json, request) -> () in
//            
//            self.friends = User.convertJsonToMultipleObjects(User.self, json: json)
//        })
//    }
//    
//    func getTransactionsBetweenFriend(friend: User, skip: Int, take: Int?, completion: (transactions: Array<Transaction>) -> ()) -> JsonRequest {
// 
//        var itemsToTake = 20
//        
//        if let take = take {
//            
//            itemsToTake = take
//        }
//        
//        let url = "\(WebApiDefaults.sharedInstance().baseUrl!)/Users/TransactionsBetween/\(UserID)/and/\(friend.UserID)?$skip=\(skip)&$top=\(itemsToTake)&$orderby=TransactionDate desc"
//
//        let request = JsonRequest.create(url, parameters: nil, method: .GET).onDownloadSuccess({ (json, request) -> () in
//
//            let transactions:Array<Transaction> = Transaction.convertJsonToMultipleObjects(Transaction.self, json: json)
//            completion(transactions: transactions)
//        })
//        
//        return request
//    }
//    
//    func getDifferenceBetweenFriend(friend: User, completion: (difference: Double, transactionsCount: Int) -> ()) -> JsonRequest {
//        
//        let url = "\(WebApiDefaults.sharedInstance().baseUrl!)/Users/DifferenceBetween/\(UserID)/and/\(friend.UserID)"
//
//        return JsonRequest.create(url, parameters: nil, method: .GET).onDownloadSuccess { (json, request) -> () in
//            
//            let difference = json["Difference"].doubleValue
//            let transactionsCount = json["TransactionsCount"].intValue
//            
//            completion(difference: difference, transactionsCount: transactionsCount)
//        }
//    }
//    
//    func getInvites(completion:(invites:Array<Array<User>>) -> ()) -> JsonRequest {
//        
//        var urlString = "\(User.webApiUrls().getUrl(UserID)!)/FriendInvitations"
//
//        return JsonRequest.create(urlString, parameters: nil, method: .GET).onDownloadSuccess { (json, request) -> () in
//
//            var allInvites = Array<Array<User>>()
//            
//            // UNCONFIRMED INVITES
//            var unconfirmedInvites = Array<User>()
//            
//            let unconfirmedInvitesJSON = json["UnconfirmedInvitations"]
//            
//            for (index: String, subJson: JSON) in unconfirmedInvitesJSON {
//                
//                let user:User = User.createObjectFromJson(subJson["User"])
//                unconfirmedInvites.append(user)
//            }
//            
//            // UNCONFIRMED SENT INVITES
//            
//            var unconfirmedSentInvites = Array<User>()
//            
//            let unconfirmedSentInvitesJSON = json["UnconfirmedSentInvitations"]
//            
//            for (index: String, subJson: JSON) in unconfirmedSentInvitesJSON {
//                
//                let user:User = User.createObjectFromJson(subJson["User"])
//                unconfirmedSentInvites.append(user)
//            }
//            
//            
//            allInvites.append(unconfirmedInvites)
//            allInvites.append(unconfirmedSentInvites)
//            
//            completion(invites: allInvites)
//        }
//    }
//    
//    func addFriend(relationUserID:Int, completion: (success: Bool) -> ()) {
//        
//        let urlString = "\(User.webApiUrls().getUrl(UserID)!)/AddFriend/\(relationUserID)"
//        
//        JsonRequest.create(urlString, parameters: nil, method: .POST).onDownloadSuccessWithRequestInfo { (json, request, httpUrlRequest, httpUrlResponse) -> () in
//            
//            completion(success: httpUrlResponse?.statusCode == 200)
//        }
//    }
//    
//    func removeFriend(relationUserID:Int, completion: (success: Bool) -> ()) {
//        
//        let urlString = "\(User.webApiUrls().getUrl(UserID)!)/RemoveFriend/\(relationUserID)"
//        
//        JsonRequest.create(urlString, parameters: nil, method: .DELETE).onDownloadSuccessWithRequestInfo { (json, request, httpUrlRequest, httpUrlResponse) -> () in
//            
//            completion(success: httpUrlResponse?.statusCode == 204)
//        }
//    }
//
//    func saveUserOnDevice() {
//
//        User.saveUserOnDevice(self as User?)
//    }
//    
//    class func saveUserOnDevice(user: User?) {
//        
//        if let u = user {
//            
//            var objectData: NSData = NSKeyedArchiver.archivedDataWithRootObject(u)
//            NSUserDefaults.standardUserDefaults().setObject(objectData, forKey: kActiveUserDefaultsKey)
//        }
//        else {
//            
//            NSUserDefaults.standardUserDefaults().removeObjectForKey(kActiveUserDefaultsKey)
//        }
//        
//        User.activeUserDidChange()
//        
//    }
//    
//    class func userSavedOnDevice() -> User? {
//        
//        if let objectData:NSData = NSUserDefaults.standardUserDefaults().objectForKey(kActiveUserDefaultsKey) as? NSData {
//            
//            let user: User = (NSKeyedUnarchiver.unarchiveObjectWithData(objectData) as? User)!
//            User.activeUserDidChange()
//            return user
//        }  
//        
//        return nil
//    }
//    
//    
//    class func activeUserDidChange() {
//        
//        //Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders?.updateValue(kActiveUser.UserID, forKey: "ActiveUserID")
//        
//        Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = [
//            "Accept-Encoding1": "deflate",
//            "Accept-Encoding": "deflate",
//            "ActiveUserID": kActiveUser.UserID
//        ]
//        
//        AppDelegate.registerForNotifications()
//    }
//    
//    required convenience init(coder decoder: NSCoder) {
//        self.init()
//        
//        if let userID = decoder.decodeObjectForKey("UserID") as? Int {
//            
//            self.UserID = userID
//        }
//        
//        if let username = decoder.decodeObjectForKey("Username") as? String {
//            
//            self.Username = username
//        }
//        
//        if let email = decoder.decodeObjectForKey("Email") as? String {
//            
//            self.Email = email
//        }
//    }
//    
//    func encodeWithCoder(coder: NSCoder) {
//        
//        coder.encodeObject(UserID, forKey: "UserID")
//        coder.encodeObject(Username, forKey: "Username")
//        coder.encodeObject(Email, forKey: "Email")
//    }
//    
////    func refreshFriendsList() -> JsonRequest {
////        
//////        var urlString = AppTools.WebMvcController(kMVCControllerName, action: "GetFriends")
//////        var data = [ "UserID" : self.UserID ]
//////        
//////        return JsonRequest.create(urlString, parameters: data, method: .POST).onDownloadSuccess({ (json, request) -> () in
//////            
//////            self.Friends = User.convertJsonToMultipleObjects(json)
//////            request.succeedContext()
//////        })
////    }
//    
////    func confirmedFriends() -> Array<User> {
////        
////        var rc = Array<User>()
////        
////        for friend in self.Friends {
////            
////            if friend.relationStatusToActiveUser == .Confirmed {
////                rc.append(friend)
////            }
////        }
////        
////        return rc
////    }
////    
////    func pendingFriends() -> Array<User> {
////        
////        var rc = Array<User>()
////        
////        for friend in self.Friends {
////            
////            if friend.relationStatusToActiveUser == .Pending {
////                rc.append(friend)
////            }
////        }
////        
////        return rc
////    }
//
//    
//    
//    class func activeUsersContaining(string: String, completion:(users:Array<User>) -> ()) -> JsonRequest {
//        
//        var urlString = "\(User.webApiUrls().getUrl(kActiveUser.UserID))/ActiveUsersMatching/\(string)"
//
//        return JsonRequest.create(urlString, parameters: nil, method: .POST).onDownloadSuccess { (json, request) -> () in
//            
//            let matches: Array<User> = User.convertJsonToMultipleObjects(User.self, json: json)
//            completion(users: matches)
//        }
//    }
//    
//    override func webApiRestObjectID() -> Int? {
//        
//        return UserID
//    }
//    
//    class func userListExcludingID(id: Int?) -> Array<User> {
//        
//        var usersToChooseFrom = [User]()
//        var allUsersInContext = [User]()
//        
//        for friend in kActiveUser.friends {
//            
//            allUsersInContext.append(friend)
//        }
//        allUsersInContext.append(kActiveUser)
//        
//        for user in allUsersInContext {
//            
//            if let excludeID = id {
//                
//                if user.UserID != excludeID{
//                    
//                    usersToChooseFrom.append(user)
//                }
//            }
//            else {
//                
//                usersToChooseFrom.append(user)
//            }
//        }
//        
//        return usersToChooseFrom
//    }
//    
//    override func modelIsValid() -> Bool {
//        
//        return Username.length() > 0 && Password.length() > 0 && Email.length() > 0
//    }
//    
//    func modelIsValidForLogin() -> Bool {
//        
//        return Username.length() > 0 && Password.length() > 0
//    }
//}
