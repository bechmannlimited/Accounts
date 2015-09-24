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
            
            view.backgroundColor = UIColor.whiteColor()
            navigationController?.setNavigationBarHidden(true, animated: false)
            
            var loginViewController = PFLogInViewController()
            
            loginViewController.fields =  PFLogInFields.Facebook | PFLogInFields.UsernameAndPassword |  PFLogInFields.SignUpButton | PFLogInFields.LogInButton | PFLogInFields.PasswordForgotten
            loginViewController.facebookPermissions = ["email", "public_profile", "user_friends"]
        
            loginViewController.logInView?.logo = titleView()
            
            var signUpViewController = PFSignUpViewController()
            loginViewController.signUpController = signUpViewController
            
            self.presentViewController(loginViewController, animated: true, completion: nil)
            
            loginViewController.delegate = self
            signUpViewController.delegate = self
        }
        else{
            
            view.showLoader()
            //checkForGraphRequestAndGoToAppWithUser(User.currentUser()!)
            goToAppAnimated(false)
            
            NSTimer.schedule(delay: 5) { timer in
             
            }
        }
    }
    
    func titleView() -> UIView {
        
        var heightWidth: CGFloat = view.frame.height >= 568 ? 120 : 60
        var topMargin: CGFloat = view.frame.height >= 568 ? -70 : -30
        var cornerRadius: CGFloat = view.frame.height >= 568 ? 15 : 8
        
        var titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: heightWidth, height: heightWidth)
 
        var logo = UIImageView()
        logo.setTranslatesAutoresizingMaskIntoConstraints(false)
        titleView.addSubview(logo)
        
        logo.image = AppTools.iconAssetNamed("iTunesArtwork")
        logo.layer.cornerRadius = cornerRadius
        logo.clipsToBounds = true
        logo.addTopConstraint(toView: titleView, relation: .Equal, constant: topMargin)
        logo.addLeftConstraint(toView: titleView, relation: .Equal, constant: 0)
        logo.addRightConstraint(toView: titleView, relation: .Equal, constant: 0)
        logo.addHeightConstraint(relation: .Equal, constant: heightWidth)

        return titleView
    }
    
    func goToAppAnimated(animated: Bool){
        
        SKTUser.currentUser().firstName = User.currentUser()?.displayName
        SKTUser.currentUser().addProperties([ "objectId" : User.currentUser()!.objectId! ])
        
        var v = UIStoryboard.initialViewControllerFromStoryboardNamed("Main")
        UIViewController.topMostController().presentViewController(v, animated: animated, completion: nil)
    }

    func checkForGraphRequestAndGoToAppWithUser(user: PFUser){
        
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if let json: AnyObject = result {
                
                let result = JSON(json)
                
                user["facebookId"] = result["id"].stringValue
                
                if user["displayName"] == nil {
                    
                    user["displayName"] = result["name"].stringValue
                }
                
                Task.sharedTasker().executeTaskInBackground({ () -> Void in
                    
                    user.save()
                    
                }, completion: { () -> () in
                    
                    self.goToAppAnimated(true)
                })
            }
            else{
                
                self.goToAppAnimated(true)
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
        ParseUtilities.showAlertWithErrorIfExists(error)
    }
}

extension StartViewController: PFSignUpViewControllerDelegate {
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        println(user)
        goToAppAnimated(true)
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        println(error)
        ParseUtilities.showAlertWithErrorIfExists(error)
    }
}
