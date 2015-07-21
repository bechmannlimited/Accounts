//
//  VerifyUserViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import Parse
import Bolts
import Alamofire

class VerifyUserViewController: ACBaseViewController {

//    var requiredTasksCompleted = 0
//    let requiredTasksTotal = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.showLoader()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        proceed()
    }
    
    func executeRequiredTasks() {
        
        //checkForUnconfirmedFriendInvites()
        //checkForUnFriendRequests()
    }
    
//    func checkForUnconfirmedFriendInvites() {
//        
//        let query = FriendRequest.query()
//        
//        query?.whereKey(kParse_FriendRequest_fromUser_Key, equalTo: User.currentUser()!)
//        query?.whereKey(kParse_FriendRequest_friendRequestStatus_Key, equalTo: FriendRequestStatus.Confirmed.rawValue)
//        
//        query?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
//            
//            println(objects?.count)
//            
//            if let unconfirmedInvites = objects as? [FriendRequest] {
//                
//                let relation = User.currentUser()!.relationForKey(kParse_User_Friends_Key)
//                
//                for friendRequest in unconfirmedInvites {
//
//                    relation.addObject(friendRequest.toUser!)
//                    friendRequest.deleteEventually()
//                }
//                
//                self.saveUserAndProceed()
//            }
//        })
//    }
    
//    func saveUserAndProceed() {
//        
//        User.currentUser()?.saveInBackgroundWithBlock({ (success, error) -> Void in
//            
//            ParseUtilities.showAlertWithErrorIfExists(error)
//            
//            if success {
//                
//                self.requiredTasksCompleted++
//                self.proceed()
//            }
//        })
//    }
    
//    func checkForUnFriendRequests() {
//        
//        let query = FriendRequest.query()
//        
//        query?.whereKey(kParse_FriendRequest_toUser_Key, equalTo: User.currentUser()!)
//        query?.whereKey(kParse_FriendRequest_friendRequestStatus_Key, equalTo: FriendRequestStatus.RequestingDeletion.rawValue)
//        
//        query?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
//            
//            let relation = User.currentUser()!.relationForKey(kParse_User_Friends_Key)
//            
//            if let deleteRequests = objects as? [FriendRequest] {
//                
//                for friendRequest in deleteRequests {
//                    
//                    relation.removeObject(friendRequest.fromUser!)
//                    friendRequest.deleteEventually() // shd have clalback?
//                }
//            }
//            
//            self.saveUserAndProceed()
//        })
//    }
    
    func proceed() {
        
//        if requiredTasksCompleted >= requiredTasksTotal {
//            
//            let v = UINavigationController(rootViewController: FriendsViewController())
//            v.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
//            presentViewController(v, animated: true, completion: nil)
//        }
//        else {
//            
//            println("not all tasks completed successfully")
//        }
        
        let v = UINavigationController(rootViewController: FriendsViewController())
        v.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        presentViewController(v, animated: true, completion: nil)
    }

}
