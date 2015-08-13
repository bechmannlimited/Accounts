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
            
            loginViewController.fields =  PFLogInFields.Facebook // | PFLogInFields.UsernameAndPassword |  PFLogInFields.SignUpButton PFLogInFields.LogInButton | PFLogInFields.PasswordForgotten |
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
            goToApp()
            
            NSTimer.schedule(delay: 5) { timer in
             
            }
        }
    }
    
    func titleView() -> UIView {
        
        var titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 400)
        
        var logo = UIImageView()
        logo.setTranslatesAutoresizingMaskIntoConstraints(false)
        titleView.addSubview(logo)
        
        logo.image = AppTools.iconAssetNamed("iTunesArtwork")
        logo.layer.cornerRadius = 20
        logo.clipsToBounds = true
        logo.addTopConstraint(toView: titleView, relation: .Equal, constant: -200)
        logo.addLeftConstraint(toView: titleView, relation: .Equal, constant: 0)
        logo.addRightConstraint(toView: titleView, relation: .Equal, constant: 0)
        logo.addHeightConstraint(relation: .Equal, constant: 200)
        
        var subTitleLabel = UILabel()
        subTitleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        titleView.addSubview(subTitleLabel)
        
        subTitleLabel.textAlignment = NSTextAlignment.Center
        subTitleLabel.text = "Please login with Facebook. Don't worry, we won't post anything!"
        subTitleLabel.numberOfLines = 0
        subTitleLabel.font = UIFont.systemFontOfSize(22)
        subTitleLabel.textColor = UIColor.lightGrayColor()
        subTitleLabel.addTopConstraint(toView: logo, attribute: NSLayoutAttribute.Bottom, relation: .Equal, constant: 10)
        subTitleLabel.addLeftConstraint(toView: titleView, relation: .Equal, constant: -30)
        subTitleLabel.addRightConstraint(toView: titleView, relation: .Equal, constant: 30)
        subTitleLabel.addHeightConstraint(relation: .Equal, constant: 120)
//
//        println(subTitleLabel.frame)
        
        return titleView
    }
    
    func goToApp(){
        
        SKTUser.currentUser().firstName = User.currentUser()?.displayName
        SKTUser.currentUser().addProperties([ "objectId" : User.currentUser()!.objectId! ])
        
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
                
                if user["displayName"] == nil {
                    
                    user["displayName"] = result["name"].stringValue
                }
                
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
