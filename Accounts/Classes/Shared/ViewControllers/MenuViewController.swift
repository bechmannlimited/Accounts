//
//  MenuViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
 
import SwiftyUserDefaults
import SwiftyJSON
import Parse
import SwiftOverlays
import AFDateHelper

private let kProfileSection = 4
private let kAboutSection = 09999
private let kTestBotSection = 3
//private let kShareSection = 2
private let kFeedbackSection = 2
private let kFriendsSection = 1
private let kSubscriptionSection = 0

private let kProfileIndexPath = NSIndexPath(forRow: 0, inSection: kProfileSection)
private let kLogoutIndexPath = NSIndexPath(forRow: 1, inSection: kProfileSection)

private let kCurrencyIndexPath = NSIndexPath(forRow: 999, inSection: 9999)

private let kFeedbackIndexPath = NSIndexPath(forRow: 0, inSection: kFeedbackSection)
private let kShareIndexPath = NSIndexPath(forRow: 1, inSection: kFriendsSection)

private let kTestBotIndexPath = NSIndexPath(forRow: 0, inSection: kTestBotSection)

private let kFriendsIndexPath = NSIndexPath(forRow: 0, inSection: kFriendsSection)

private let kAboutIndexPath = NSIndexPath(forItem: 0, inSection: kAboutSection)

private let kSubscriptionIndexPath = NSIndexPath(forItem: 0, inSection: kSubscriptionSection)

protocol MenuDelegate {
    
    func menuDidClose()
}

class MenuViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    var data = [
        [kSubscriptionIndexPath],
        [kFriendsIndexPath, kShareIndexPath],
        [kFeedbackIndexPath],
        [kTestBotIndexPath],
        //[kAboutIndexPath],
        [kProfileIndexPath, kLogoutIndexPath]
    ]
    
    var hasAppearedFirstTime = false
    
    var delegate: MenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView(tableView, delegate: self, dataSource: self)
        addCloseButton()
        title = "Settings"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        deselectSelectedCell(tableView)
        
        if hasAppearedFirstTime {
            
            getInvites()
        }
        
        hasAppearedFirstTime = true
    }
    
    func testBotSwitchIsChanged(testBotSwitch: UISwitch) {
        
        Settings.setShouldShowTestBot(testBotSwitch.on)
    }
    
    func getInvites() {
        
        self.tableView.reloadRowsAtIndexPaths([kFriendsIndexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
}

extension MenuViewController: UITableViewDataSource {
    
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
        
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = ""
        cell.accessoryView = nil
        cell.accessoryType = UITableViewCellAccessoryType.None
        
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
            cell.accessoryType = .DisclosureIndicator
        }
        else if indexPath == kFeedbackIndexPath {
         
            cell.textLabel?.text = "Contact support team"
            
            let date = NSDate()
            
            let dateFormatter: NSDateFormatter = NSDateFormatter()
            dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT+1")
            
            let localizedDateString = dateFormatter.stringFromDate(date)
            
            let localizedDate = NSDate(fromString: localizedDateString, format: .Custom(dateFormatter.dateFormat))
            let online = localizedDate.timeIntervalSince1970 >= localizedDate.dateAtStartOfDay().dateByAddingHours(9).timeIntervalSince1970 && localizedDate.timeIntervalSince1970 <= localizedDate.dateAtStartOfDay().dateByAddingHours(21).timeIntervalSince1970
            
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
            
            cell.textLabel?.text = "Enable ioubot"
            
            let testBotSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
            testBotSwitch.on = Settings.shouldShowTestBot()
            testBotSwitch.addTarget(self, action: Selector("testBotSwitchIsChanged:"), forControlEvents: UIControlEvents.ValueChanged)

            cell.accessoryView = testBotSwitch
        }
        else if indexPath == kFriendsIndexPath {
            
            cell.textLabel?.text = "Friend invites"
            cell.detailTextLabel?.text = "Send an invite"
            cell.accessoryType = .DisclosureIndicator

            User.currentUser()?.getInvites({ (invites) -> () in
                
                let i = User.currentUser()!.pendingInvitesCount()
                
                cell.detailTextLabel?.text = i > 0 ? "\(i)" : "Send an invite"
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            })
        }
        else if indexPath == kAboutIndexPath {
            
            cell.textLabel?.text = "About"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        else if indexPath == kSubscriptionIndexPath {
            
            cell.textLabel?.text = "Subscription"
            
            var s = ""
            
            if User.currentUser() != nil {
                
                s = User.currentUser()!.userType == UserType.ProUser.rawValue ? "Pro" : "Get Pro"
            }
            
            User.currentUser()?.fetchInBackgroundWithBlock({ (_, error) -> Void in
                
                if error == nil && User.currentUser() != nil {
                    
                    s = User.currentUser()!.userType == UserType.ProUser.rawValue ? "Pro" : "Get Pro"
                    cell.detailTextLabel?.text = s
                }
            })
            
            cell.detailTextLabel?.text = s
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath == kCurrencyIndexPath {
            
            //let v = SelectCurrencyViewController()
            //navigationController?.pushViewController(v, animated: true)
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
                            
                            Task.sharedTasker().executeTaskInBackground({ () -> () in
                                
                                User.currentUser()?.unpin()
                                PFObject.unpinAll(User.query()?.fromLocalDatastore().findObjects())
                                PFObject.unpinAll(Transaction.query()?.fromLocalDatastore().findObjects())
                                
                            }, completion: { () -> () in
                                
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
            
            let v = SaveUserViewController()
            v.delegate = self
            navigationController?.pushViewController(v, animated: true)
        }
        else if indexPath == kFeedbackIndexPath{
            
            SupportKit.show()
        }
        else if indexPath == kShareIndexPath {
            
            _ = "Download iou from the app store!"
            
            if let myWebsite = NSURL(string: "itms://itunes.apple.com/us/app/iou-shared-expenses/id1024589247?ls=1&mt=8")
            {
                let objectsToShare = [myWebsite] //textToShare
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                activityVC.completionWithItemsHandler = { items in
                    
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
                
                let cell = tableView.cellForRowAtIndexPath(indexPath)!
                
                if kDevice == .Pad {
                    
                    activityVC.popoverPresentationController!.sourceView = cell.contentView
                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 140, height: cell.contentView.frame.height)
                }
                
                self.presentViewController(activityVC, animated: true, completion: nil)
            }
        }
        else if indexPath == kTestBotIndexPath {
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        else if indexPath == kFriendsIndexPath {
            
            let v = FriendInvitesViewController()
            navigationController?.pushViewController(v, animated: true)
        }
        else if indexPath == kAboutIndexPath {
            
            let v = AboutViewController()
            navigationController?.pushViewController(v, animated: true)
        }
        else if indexPath == kSubscriptionIndexPath {
            
            if User.currentUser() != nil {
                
                if User.currentUser()!.userType == UserType.ProUser.rawValue {
                    
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
                else {
                    
                    User.currentUser()?.launchProSubscriptionDialogue("A Pro subscription will give you access to extra features including secure transactions!", completion: ({
                    
                        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                        self.tableView.reloadRowsAtIndexPaths([kSubscriptionIndexPath], withRowAnimation: UITableViewRowAnimation.None)
                    }))
                }
            }
            else {
                
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == kProfileSection {
            
            return "Logged in as \(User.currentUser()!.namePrioritizingDisplayName())"
        }
        
        return ""
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section == kFeedbackSection {
            
            return "Send a message to our support team at any time and we'll respond asap (online 09:00 - 21:00 GMT+1)"
        }
        else if section == kTestBotSection {
            
            return "Use ioubot to test out the app before all your friends get setup. "
        }
        else if section == kFriendsSection {
            
            let username = User.currentUser()?.username
            let displayName = User.currentUser()?.displayName
            
            var text = ""
            var namesAdded = 0
            
            if displayName?.isEmpty == false {
                
                text += "\"\(displayName!)\""
                namesAdded++
            }
            if username?.isEmpty == false && User.currentUser()?.facebookId == nil {
                
                let connector = namesAdded == 0 ? "" : ", "
                text += "\(connector)\"\(username!)\""
            }
            
            let orYourEmail: String = User.currentUser()?.email?.isEmpty == false ? " or your email" : ""
            text = "Your friends can find you by searching for \(text)\(orYourEmail) in the friend invites section. "
            
            if User.currentUser()?.facebookId != nil {
                
                text += "Your Facebook friends who have this app, will appear in your friends list!"
            }
           
            return text
        }
        
        return nil
    }
    
    override func appDidResume() {
        super.appDidResume()
        
        tableView.reloadData()
    }
    
    override func close() {
        super.close()
        
        delegate?.menuDidClose()
    }
}

extension MenuViewController: SaveUserDelegate {
    
    func didSaveUser() {
        
        tableView.reloadData()
    }
}

