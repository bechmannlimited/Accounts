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
import SwiftOverlays

class StartViewController: ACBaseViewController {
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        SKTUser.currentUser().firstName = nil
//        SKTUser.currentUser().addProperties([ "objectId" : "" ])
        
        //view.backgroundColor = AccountColor.blueColor()
        
        if PFUser.currentUser() == nil {
            
            view.backgroundColor = UIColor.whiteColor()
            navigationController?.setNavigationBarHidden(true, animated: false)
            
            let loginViewController = PFLogInViewController()
            
            loginViewController.fields =  [PFLogInFields.Facebook, PFLogInFields.UsernameAndPassword, PFLogInFields.SignUpButton, PFLogInFields.LogInButton, PFLogInFields.PasswordForgotten]
            loginViewController.facebookPermissions = ["email", "public_profile", "user_friends"]
        
            loginViewController.logInView?.logo = titleView()
            
            let signUpViewController = PFSignUpViewController()
            loginViewController.signUpController = signUpViewController
            
            signUpViewController.signUpView?.logo = titleView()
            
            self.presentViewController(loginViewController, animated: true, completion: nil)
            
            loginViewController.delegate = self
            signUpViewController.delegate = self
            
            let helpButton = UIButton(frame: CGRect(x: -8, y: kDevice == .Pad ? 0 : 20, width: 100, height: 40))
            helpButton.setTitle("Get help", forState: UIControlState.Normal)
            helpButton.setTitleColor(AccountColor.blueColor(), forState: UIControlState.Normal)
            helpButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Highlighted)
            helpButton.addTarget(self, action: "help", forControlEvents: UIControlEvents.TouchUpInside)
            loginViewController.view.addSubview(helpButton)
            
        }
        else{
            
            view.showLoader()
            //checkForGraphRequestAndGoToAppWithUser(User.currentUser()!)
            goToAppAnimated(false)
            
            NSTimer.schedule(delay: 5) { timer in
             
            }
        }
    }
    
    func help() {
        
        SupportKit.show()
    }
    
    func titleView() -> UIView {
        
        let heightWidth: CGFloat = view.frame.height >= 568 ? 120 : 60
        let topMargin: CGFloat = view.frame.height >= 568 ? -70 : -30
        let cornerRadius: CGFloat = view.frame.height >= 568 ? 15 : 8
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: heightWidth, height: heightWidth)
 
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
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
        
        User.currentUser()?.fetchInBackgroundWithBlock({ (_, error) -> Void in
            
            print("completed customer fetch with error: \(error)")
        })
        
        let v = UIStoryboard.initialViewControllerFromStoryboardNamed("Main")
        UIViewController.topMostController().presentViewController(v, animated: animated, completion: nil)
    }

    func checkForGraphRequestAndGoToAppWithUser(user: PFUser){
        
        SwiftOverlays.showBlockingWaitOverlayWithText(User.currentUser()?.facebookId != nil ? "Fetching facebook info..." : "Setting some things up...")
        
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if let json: AnyObject = result {
                
                let result = JSON(json)
                print(result)
                user["facebookId"] = result["id"].stringValue
                
                if user["displayName"] == nil {
                    
                    user["displayName"] = result["name"].stringValue
                }
//                if user["email"] == nil {
//                    
//                    user["email"] = result["email"].stringValue
//                }
                
                Task.sharedTasker().executeTaskInBackground({ () -> Void in
                    
                    do { try user.save() } catch
                    {
                        user.saveEventually()
                    }
                    
                }, completion: { () -> () in
                    
                    SwiftOverlays.removeAllBlockingOverlays()
                    self.setPreferredCurrencyIdIfNecessary()
                    self.goToAppAnimated(true)
                })
            }
            else{
                
                SwiftOverlays.removeAllBlockingOverlays()
                self.setPreferredCurrencyIdIfNecessary()
                self.goToAppAnimated(true)
            }
        })
    }
    
    func setPreferredCurrencyIdIfNecessary() {
        
        if let id = User.currentUser()?.preferredCurrencyId {
            
            Settings.setDefaultCurrencyId(id)
        }
    }
}

extension StartViewController: PFLogInViewControllerDelegate{
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        
        SwiftOverlays.showBlockingWaitOverlayWithText("Setting some things up...")
        
        Task.sharedTasker().executeTaskInBackground({ () -> () in
            
            do { try User.currentUser()?.fetch() } catch {}
            do { try PFObject.unpinAll(User.query()?.fromLocalDatastore().findObjects()) } catch {}
            do { try PFObject.unpinAll(Transaction.query()?.fromLocalDatastore().findObjects()) } catch {}
            
        }, completion: { () -> () in

            SwiftOverlays.removeAllBlockingOverlays()
            self.setPreferredCurrencyIdIfNecessary()
            self.checkForGraphRequestAndGoToAppWithUser(user)
        })
    }
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        print(error)
        ParseUtilities.showAlertWithErrorIfExists(error)
    }
}

extension StartViewController: PFSignUpViewControllerDelegate {
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        
        SwiftOverlays.showBlockingWaitOverlayWithText("Setting some things up...")
        
        Task.sharedTasker().executeTaskInBackground({ () -> () in
            
            do { try User.currentUser()?.fetch() } catch {}
            do { try PFObject.unpinAll(User.query()?.fromLocalDatastore().findObjects()) } catch {}
            do { try PFObject.unpinAll(Transaction.query()?.fromLocalDatastore().findObjects()) } catch {}
            
        }, completion: { () -> () in
            
            SwiftOverlays.removeAllBlockingOverlays()
            self.goToAppAnimated(true)
        })
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        print(error)
        ParseUtilities.showAlertWithErrorIfExists(error)
    }
}
