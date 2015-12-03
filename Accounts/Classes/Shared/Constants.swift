////
////  Constants.swift
////  Accounts
////
////  Created by Alex Bechmann on 15/08/2015.
////  Copyright (c) 2015 Alex Bechmann. All rights reserved.
////
//
//import Foundation
//

let kTestBotObjectId = "soRCUYqg6W"
let kSaveTimeoutForRemoteUpdate: NSTimeInterval = 6
let kDeleteTimeoutForRemoteUpdate: NSTimeInterval = 3

let kProSubscriptionProductID = "iouProSubscription"

private let kIsSecureDescriptionIos9SpecifcText = NKTouchID.touchIDIsAvailableForIOUApp() ? "This will also secure it with TouchID." : ""

private var kIsSecureRequiresSubscription: String {

    get {
        return "" // while pro sub not developed yet
        return User.currentUser()?.userType == UserType.ProUser.rawValue ? "" : "NB: Requires Pro subscription."
    }
}

var kIsSecureDescription: String {

    get {
        
        return "This will hide the text and amount on the transactions screen so you don't give away secret payments! \(kIsSecureDescriptionIos9SpecifcText) \(kIsSecureRequiresSubscription)"
    }
}