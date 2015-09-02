//
//  MenuViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import SwiftyUserDefaults
import SwiftyJSON
import Parse
import AFDateHelper
import SwiftOverlays

private let kProfileSection = 3
private let kTestBotSection = 2
private let kShareSection = 1
private let kFeedbackSection = 0

private let kProfileIndexPath = NSIndexPath(forRow: 09999, inSection: kProfileSection)
private let kLogoutIndexPath = NSIndexPath(forRow: 0, inSection: kProfileSection)

private let kCurrencyIndexPath = NSIndexPath(forRow: 999, inSection: 9999)

private let kFeedbackIndexPath = NSIndexPath(forRow: 0, inSection: kFeedbackSection)
private let kShareIndexPath = NSIndexPath(forRow: 0, inSection: kShareSection)

private let kTestBotIndexPath = NSIndexPath(forRow: 0, inSection: kTestBotSection)

//protocol MenuDelegate {
//    
//    func menuDidClose()
//}

class MenuViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    var data = [
        [kFeedbackIndexPath],
        [kShareIndexPath],
        [kTestBotIndexPath],
        [kLogoutIndexPath]
    ]
    
    //var delegate: MenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView(tableView, delegate: self, dataSource: self)
        addCloseButton()
        title = "Settings"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        deselectSelectedCell(tableView)
    }
    
    func testBotSwitchIsChanged(testBotSwitch: UISwitch) {
        
        Settings.setShouldShowTestBot(testBotSwitch.on)
    }
}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return data.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
        })
        
        cell.accessoryView = nil
        
        if indexPath == kCurrencyIndexPath {
            
            cell.textLabel?.text = "Currency"
            cell.detailTextLabel?.text = Defaults[kCurrencySettingKey].string
            cell.accessoryType = .DisclosureIndicator
        }
        else if indexPath == kLogoutIndexPath {
            
            cell.textLabel?.text = "Logout"
        }
        else if indexPath == kProfileIndexPath {
            
            cell.textLabel?.text = "Edit profile"
        }
        else if indexPath == kFeedbackIndexPath {
         
            cell.textLabel?.text = "Contact support team"
            
            var date = NSDate()
            
            var dateFormatter: NSDateFormatter = NSDateFormatter()
            dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT+1")
            
            let localizedDateString = dateFormatter.stringFromDate(date)
            let localizedDate = NSDate(fromString: localizedDateString, format: .Custom(dateFormatter.dateFormat))
            let online = localizedDate >= localizedDate.dateAtStartOfDay().dateByAddingHours(9) && localizedDate <= localizedDate.dateAtStartOfDay().dateByAddingHours(21)
            
            cell.detailTextLabel?.text = online ? "online" : "offline"
            
            let dotColor = online ? AccountColor.greenColor() : AccountColor.redColor()
            let dot = UIImageView(image: UIImage.imageWithColor(dotColor, size: CGSize(width: 7, height: 7)))
            dot.clipsToBounds = true
            dot.layer.cornerRadius = dot.frame.width / 2
            
            cell.accessoryView = dot
        }
        else if indexPath == kShareIndexPath {
            
            cell.textLabel?.text = "Share app link"
        }
        else if indexPath == kTestBotIndexPath {
            
            cell.textLabel?.text = "Enable TestBot"
            
            let testBotSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            testBotSwitch.on = Settings.shouldShowTestBot()
            testBotSwitch.addTarget(self, action: Selector("testBotSwitchIsChanged:"), forControlEvents: UIControlEvents.ValueChanged)

            
            cell.accessoryView = testBotSwitch
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath == kCurrencyIndexPath {
            
            let v = SelectCurrencyViewController()
            navigationController?.pushViewController(v, animated: true)
        }
        else if indexPath == kLogoutIndexPath {
            
            UIAlertController.showAlertControllerWithButtonTitle("Logout", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Are you sure you want to logout?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    Task.sharedTasker().cancelAllTasks()
                    
                    //remove user from installation
                    let installation = PFInstallation.currentInstallation()
                    installation.removeObjectForKey(kParseInstallationUserKey)
                    
                    SwiftOverlays.showBlockingWaitOverlayWithText("Logging out...")
                    
                    installation.saveInBackgroundWithBlock({ (success, error) -> Void in
                        
                        if success {
                            
                            User.logOutInBackgroundWithBlock({ (error) -> Void in
                                
                                SwiftOverlays.removeAllBlockingOverlays()
                                
                                if let error = error {
                                    
                                    ParseUtilities.showAlertWithErrorIfExists(error)
                                    self.deselectSelectedCell(tableView)
                                }
                                else {
                                    
                                    let v = UIStoryboard.initialViewControllerFromStoryboardNamed("Login")
                                    self.presentViewController(v, animated: true, completion: nil)
                                }
                            })
                        }
                        else {
                            
                            SwiftOverlays.removeAllBlockingOverlays()
                            UIAlertView(title: "Error", message: "You need to be connected to the internet to logout, so that we can stop you receiving push notifications.", delegate: nil, cancelButtonTitle: "Ok").show()
                            self.deselectSelectedCell(tableView)
                        }
                    })
                }
                else {
                    
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
            })
        }
        else if indexPath == kProfileIndexPath {
            
            if User.currentUser()?.facebookId == nil {
                
                let v = SaveUserViewController()
                navigationController?.pushViewController(v, animated: true)
            }
            else{
                
                UIAlertView(title: "Not ready yet!", message: "You cant view your profile if you are logged in via facebook for the moment.", delegate: nil, cancelButtonTitle: "Ok").show()
                
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        else if indexPath == kFeedbackIndexPath{
            
            SupportKit.show()
        }
        else if indexPath == kShareIndexPath {
            
            let textToShare = "Download iou from the app store!"
            
            if let myWebsite = NSURL(string: "itms://itunes.apple.com/us/app/iou-shared-expenses/id1024589247?ls=1&mt=8")
            {
                let objectsToShare = [myWebsite] //textToShare
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                activityVC.completionWithItemsHandler = { items in
                    
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
                
                self.presentViewController(activityVC, animated: true, completion: nil)
            }
        }
        else if indexPath == kTestBotIndexPath {
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == kProfileSection {
            
            return "Logged in as \(String.emptyIfNull(User.currentUser()?.displayName))"
        }
        
        return ""
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section == kFeedbackSection {
            
            return "Send a message to our support team at any time and we'll respond asap (online 09:00 - 21:00 GMT+1)"
        }
        else if section == kShareSection {
            
            return "Your Facebook friends who have this app, will appear in your friends list!"
        }
        
        return nil
    }
    
    override func appDidResume() {
        super.appDidResume()
        
        tableView.reloadData()
    }
}

