//
//  Extensions.swift
//  Accounts
//
//  Created by Alex Bechmann on 15/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

extension String {
    
    static func emptyIfNull(str: String?) -> String {
        
        return str != nil ? str! : ""
    }
}