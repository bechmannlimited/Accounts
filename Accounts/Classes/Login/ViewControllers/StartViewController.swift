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

class StartViewController: UIViewController {

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.currentUser() == nil {
            
            var loginViewController = PFLogInViewController()
            loginViewController.delegate = self
            loginViewController.fields = PFLogInFields.UsernameAndPassword | PFLogInFields.LogInButton | PFLogInFields.SignUpButton | PFLogInFields.PasswordForgotten | PFLogInFields.Facebook
            
            var signUpViewController = PFSignUpViewController()
            signUpViewController.delegate = self
            
            loginViewController.signUpController = signUpViewController
            
            self.presentViewController(loginViewController, animated: true, completion: nil)
        }
        else{
            
            goToApp()
        }
    }
    
    func goToApp(){
        
        var v = UIStoryboard.initialViewControllerFromStoryboardNamed("Main")
        self.presentViewController(v, animated: true, completion: nil)
    }

}

extension StartViewController: PFLogInViewControllerDelegate{
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        println(user)
        goToApp()
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
