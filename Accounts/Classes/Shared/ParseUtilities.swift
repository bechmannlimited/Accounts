//
//  ParseUtilities.swift
//  Accounts
//
//  Created by Alex Bechmann on 13/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import Parse

public class ParseUtilities: NSObject {
   
    public class func showAlertWithErrorIfExists(error: NSError?) {
        
        if let err = error?.localizedDescription {
        
            UIAlertView(title: "Error!", message: err, delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    public class func performQueryLocallyAndRemotely(query: PFQuery?) {
        
        
    }
    
    class func sendPushNotificationsInBackgroundToUsers(users: [User], message: String) {
        
        let query = PFInstallation.query()
        
        for user in users {
            
            query?.whereKey("user", equalTo: user)
        }
        
        let pushNotification = PFPush()
        pushNotification.setQuery(query)
        pushNotification.setMessage(message)
        pushNotification.sendPushInBackground()
    }
    
}
