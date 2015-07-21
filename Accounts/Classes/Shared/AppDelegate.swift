//
//  AppDelegate.swift
//  Accounts
//
//  Created by Alex Bechmann on 05/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import SwiftyUserDefaults
import Alamofire
import Parse
import Bolts

//var kActiveUser:User = User.object()
let kDevice = UIDevice.currentDevice().userInterfaceIdiom

let kViewBackgroundColor = UIColor.groupTableViewBackgroundColor()
let kViewBackgroundGradientTop =  AccountColor.blueColor()
let kViewBackgroundGradientBottom =  AccountColor.greenColor()

let kTableViewBackgroundColor = UIColor.clearColor()

let kTableViewCellBackgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.55)
let kTableViewCellTextColor = UIColor.whiteColor()
let kTableViewCellDetailTextColor = UIColor.whiteColor()
let kTableViewCellSeperatorStyle = UITableViewCellSeparatorStyle.SingleLine
let kTableViewCellSeperatorColor = UIColor.clearColor()
let kTableViewCellHeight: CGFloat = 50
let kTableViewCellTintColor = UIColor.whiteColor()

let kNavigationBarPositiveActionColor = kNavigationBarTintColor
let kNavigationBarTintColor = UIColor(hex: "00AEE5")
let kNavigationBarBarTintColor:UIColor = UIColor.whiteColor().colorWithAlphaComponent(0.95)
let kNavigationBarTitleColor = UIColor.blackColor()
let kNavigationBarStyle = UIBarStyle.Default

let kFormDeleteButtonTextColor = AccountColor.negativeColor()

let kTableViewMaxWidth:CGFloat = 570
let kTableViewCellIpadCornerRadiusSize = CGSize(width: 5, height: 5)

let kDefaultSeperatorColor = UITableView().separatorColor

let kParseInstallationUserKey = "user"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        setupAppearances()
        
        //parse
        User.registerSubclass()
        FriendRequest.registerSubclass()
        Transaction.registerSubclass()
        Purchase.registerSubclass()
        
        //Parse.enableLocalDatastore()
        
        Parse.setApplicationId("d24X8b7STLrPskMNRBVgs30iI1G6cG1lGqsPqeMN",
            clientKey: "fR5DJfzy5x9qlYLiD4xfLd46GmAH1QCWhV1Q8SKc")
        
        // Register for Push Notitications
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                //PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        
        if User.currentUser() == nil {
            
            setWindowToLogin()
        }
        
        return true
    }
    
    class func registerForNotifications() {
        
        let application = UIApplication.sharedApplication()
        
        let userNotificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    func setupGoogleMapApi(){
        
        //GMSServices.provideAPIKey("AIzaSyCwDKp9Ev7BLRdf_Y4iymmDz4-PsmVISiw")
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
        //UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.channels = []
        
        if let user = User.currentUser() {
            
            installation.setObject(user, forKey: kParseInstallationUserKey)
        }
        
        installation.saveInBackground()
        println(deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            println("Push notifications are not supported in the iOS Simulator.")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        if application.applicationState == UIApplicationState.Inactive {
            //PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
        println(userInfo)
    }
    
    func setupAppearances() {
        
        UINavigationBar.appearance().tintColor = kNavigationBarTintColor
        //UINavigationBar.appearance().barTintColor = kNavigationBarBarTintColor
        //UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage.imageWithColor(kNavigationBarBarTintColor, size: CGSize(width: 10, height: 10)), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().barStyle = kNavigationBarStyle
        
        UIToolbar.appearance().tintColor = kNavigationBarTintColor
        
        UITableViewCell.appearance().tintColor = kNavigationBarTintColor
        
        UITabBar.appearance().tintColor = kNavigationBarTintColor
    }
    
    private func setWindowToLogin() {
        
        let bounds: CGRect = UIScreen.mainScreen().bounds
        window = UIWindow(frame: bounds)
        window?.rootViewController = UIStoryboard.initialViewControllerFromStoryboardNamed("Login")
        window?.makeKeyAndVisible()
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        application.applicationIconBadgeNumber = 0;
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

