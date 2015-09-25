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
import ParseFacebookUtilsV4
import KFSwiftImageLoader
import GoogleMaps
import SwiftyJSON
//import ParseCrashReporting

let kDevice = UIDevice.currentDevice().userInterfaceIdiom

let kViewBackgroundColor = AccountColor.grayColor()
let kViewBackgroundGradientTop =  AccountColor.blueColor()
let kViewBackgroundGradientBottom =  AccountColor.greenColor()

let kDarkColor = UIColor(hex: "252525")

let kTableViewCellBackgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.55)
let kTableViewCellHeight: CGFloat = 50

let kTableViewBackgroundColor = UIColor.clearColor()
let kTableViewSeparatorColor = UITableView().separatorColor

let kNavigationBarPositiveActionColor = kNavigationBarTintColor
let kNavigationBarTintColor = UIColor(hex: "00AEE5")
let kNavigationBarBarTintColor:UIColor =  UIColor.whiteColor()
let kNavigationBarStyle = UIBarStyle.Default

let kFormDeleteButtonTextColor = AccountColor.redColor()

let kTableViewMaxWidth:CGFloat = 570
let kTableViewCellIpadCornerRadiusSize = CGSize(width: 5, height: 5)

let kAnimationDuration:NSTimeInterval = 0.5

let kParseInstallationUserKey = "user"
let kNotificationCenterPushNotificationKey = "pushNotificationUserInfoReceived"
let kNotificationCenterSaveEventuallyItemDidSaveKey = "saveEventuallyItemDidSave"

let kDefaultNavigationBarShadowImage = UINavigationBar().shadowImage // UIImage.imageWithColor(.clearColor(), size: CGSize(width: 1, height: 1))

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
        
        //ParseCrashReporting.enable()
        Parse.enableLocalDatastore()
        Parse.setApplicationId("Nc2fYkKYCVLImrZx1ZX1RKv7f4PFDVZ3xLmkDmwM",
            clientKey: "ZqLepxDYLImFaybsC4CboyWX8OppfYGUPZUj6r5X")
        
        setWindowToLogin()
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        SupportKit.initWithSettings(SKTSettings(appToken: "amtp9h7tc5dq2sby4q6yc5ke6"))
        
        GMSServices.provideAPIKey("AIzaSyB7bF8J5Oe5E87ovtdy7l1MRvpe3Rc1zkU")
        
        return true
    }
    
    class func registerForNotifications() {
        
        let application = UIApplication.sharedApplication()
        
        let userNotificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.channels = []
        
        if let user = User.currentUser() {
            
            installation.setObject(user, forKey: kParseInstallationUserKey)
        }
        
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            println("Push notifications are not supported in the iOS Simulator.")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        println(userInfo)

        if userInfo.indexForKey("iouEvent") != nil {
            
            if let value = userInfo["iouEvent"] as? String {
                
                if value == IOUEvent.ItemSaved.rawValue {

                    if let currentUserId = userInfo["currentUserId"] as? String {
                        
                        println("\(User.currentUser()?.objectId) - \(currentUserId)")
                        
                        if User.currentUser()?.objectId != currentUserId {
                            
                            if let message = userInfo["message"] as? String {
                                
                                HDNotificationView.showNotificationViewWithImage(AppTools.iconAssetNamed("iTunesArtwork"), title: "iou", message: message, isAutoHide: true, onTouch: { () -> Void in
                                    
                                })
                            }
                        }
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationCenterSaveEventuallyItemDidSaveKey, object: nil, userInfo: nil)
                }
            }
        }
    }
    
    func setupAppearances() {
                
        UINavigationBar.appearance().tintColor = kNavigationBarTintColor
        //UINavigationBar.appearance().setBackgroundImage(UIImage.imageWithColor(UIColor.redColor(), size: CGSize(width: 10, height: 10)), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().shadowImage = kDefaultNavigationBarShadowImage
        UINavigationBar.appearance().barStyle = kNavigationBarStyle
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont.boldFont(17)]
        
        UIToolbar.appearance().tintColor = kNavigationBarTintColor
        
        UITableViewCell.appearance().tintColor = kNavigationBarTintColor
        
        UITabBar.appearance().tintColor = kNavigationBarTintColor
        
        UITableView.appearance().backgroundColor = .clearColor()
        
        UITextField.appearance().tintColor = kNavigationBarTintColor
        
        UISwitch.appearance().onTintColor = AccountColor.greenColor()
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
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
//    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
//    
//        FBSDKAppEvents.
//        return true
//    }

}

