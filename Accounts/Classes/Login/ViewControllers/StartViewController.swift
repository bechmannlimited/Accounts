//
//  StartViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 27/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import ParseFacebookUtilsV4
import SwiftyJSON

class StartViewController: ACBaseViewController {

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.currentUser() == nil {
            
            var loginViewController = PFLogInViewController()
            
            loginViewController.fields = PFLogInFields.UsernameAndPassword | PFLogInFields.LogInButton | PFLogInFields.SignUpButton | PFLogInFields.PasswordForgotten | PFLogInFields.Facebook
            loginViewController.facebookPermissions = ["email", "public_profile", "user_friends"]
            
            var signUpViewController = PFSignUpViewController()
            loginViewController.signUpController = signUpViewController
            
            self.presentViewController(loginViewController, animated: true, completion: nil)
            
            loginViewController.delegate = self
            signUpViewController.delegate = self
        }
        else{
            
            view.showLoader()
            //checkForGraphRequestAndGoToAppWithUser(User.currentUser()!)
            goToApp()
            
            NSTimer.schedule(delay: 5) { timer in
             
            }
        }
    }
    
    func goToApp(){
        
        var v = UIStoryboard.initialViewControllerFromStoryboardNamed("Main")
        UIViewController.topMostController().presentViewController(v, animated: false, completion: nil)
    }

    func checkForGraphRequestAndGoToAppWithUser(user: PFUser){
        
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if let json: AnyObject = result {
                
                let result = JSON(json)
                println(result)
                user["facebookId"] = result["id"].stringValue
                user["displayName"] = result["name"].stringValue
                
                Task.executeTaskInBackground({ () -> () in
                    
                    user.save()
                    
                }, completion: { () -> () in
                        
                    self.goToApp()
                })
            }
            else{
                
                self.goToApp()
            }
        })
    }
}

extension StartViewController: PFLogInViewControllerDelegate{
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        
        checkForGraphRequestAndGoToAppWithUser(user)
    }
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        println(error)
    }
}

extension StartViewController: PFSignUpViewControllerDelegate {
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        println(user)
        goToApp()
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        println(error)
    }
}
