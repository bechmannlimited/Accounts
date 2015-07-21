//
//  Friend.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import SwiftyJSON

//class Friend: User {
//    
//    //var relationStatusToActiveUser: RelationStatus = RelationStatus.Undefined
//    //var DifferenceBetweenActiveUser: Double = 0
//    
//    // MARK: - Web api methods
//    
//    override func setExtraPropertiesFromJSON(json: JSON) {
//        
//        super.setPropertiesFromJson(json)
//    }
//    
//    override class func webApiUrls() -> WebApiManager {
//        
//        return WebApiManager().setupUrlsForREST("User")
//    }
//    
//    override func webApiRestObjectID() -> Int? {
//        
//        return UserID
//    }
//    
//    override func registerClassesForJsonMapping() {
//        super.registerClassesForJsonMapping()
//        
//        registerProperty("DifferenceBetweenActiveUser", withJsonKey: "Difference")
//    }
//    
//    required convenience init(coder decoder: NSCoder) {
//        self.init()
//    }
//    
//    override func encodeWithCoder(coder: NSCoder) {
//
//    }
//}
