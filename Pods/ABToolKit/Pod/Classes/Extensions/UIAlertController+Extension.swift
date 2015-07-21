//
//  UIAlertController+Extension.swift
//  objectmapperTest
//
//  Created by Alex Bechmann on 28/04/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

public enum AlertResponse: Int{
    
    case Cancel = 0
    case Confirm = 1
}

public extension UIAlertController {
    
    public func show() {

        UIViewController.topMostController().presentViewController(self, animated: true) { () -> Void in
        }
    }
    
    public class func showAlertControllerWithButtonTitle(confirmBtnTitle:String, confirmBtnStyle:UIAlertActionStyle, message:String, completion:(response: AlertResponse) -> ()) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
            completion(response: AlertResponse.Cancel)
        }
        alertController.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: confirmBtnTitle, style: confirmBtnStyle) { (action) in
            
            completion(response: AlertResponse.Confirm)
        }
        alertController.addAction(confirmAction)
        
        UIViewController.topMostController().presentViewController(alertController, animated: true){}
    }
}