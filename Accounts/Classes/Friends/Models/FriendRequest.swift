//
//  FriendRequest.swift
//  Accounts
//
//  Created by Alex Bechmann on 12/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import Parse

enum FriendRequestStatus : Int {
    
    case None = 0
    case Pending = 1
    case Confirmed = 2
    case RequestingDeletion = 3
}

class FriendRequest: PFObject {
   
    @NSManaged var fromUser: User?
    @NSManaged var toUser: User?
    @NSManaged var friendRequestStatus: Int
}

extension FriendRequest: PFSubclassing {
    
    static func parseClassName() -> String {
        
        return FriendRequest.getClassName()
    }
}
