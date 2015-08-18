//
//  Font.swift
//  Accounts
//
//  Created by Alex Bechmann on 17/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

//let kFontBaseName = "W4"
let kFontMainBaseName = "HelveticaNeue"
// "HiraMaruProN-W4"

private let kFontMainLight = "\(kFontMainBaseName)-Light"
private let kFontMainNormal = "\(kFontMainBaseName)"
private let kFontMainBold = "\(kFontMainBaseName)-Bold"

import UIKit

extension UIFont {
   
    class func lightFont(size: CGFloat) -> UIFont {
        
        //return UIFont.systemFontOfSize(size)
        return UIFont(name: kFontMainLight, size: size)!
    }
    
    class func normalFont(size: CGFloat) -> UIFont {
        //return UIFont.systemFontOfSize(size)
        return UIFont(name: kFontMainNormal, size: size)!
    }
    
    class func boldFont(size: CGFloat) -> UIFont {
        //return UIFont.systemFontOfSize(size)
        return UIFont(name: kFontMainBold, size: size)!
    }
}
