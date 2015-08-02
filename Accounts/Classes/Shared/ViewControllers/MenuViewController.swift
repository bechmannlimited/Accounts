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

private let kProfileSection = 0
private let kCurrencySection = 1
//private let kLogoutSection = 2

private let kProfileIndexPath = NSIndexPath(forRow: 0, inSection: kProfileSection)
private let kLogoutIndexPath = NSIndexPath(forRow: 1, inSection: kProfileSection)

private let kCurrencyIndexPath = NSIndexPath(forRow: 0, inSection: kCurrencySection)

//protocol MenuDelegate {
//    
//    func menuDidClose()
//}

class MenuViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    var data = [
        [kProfileIndexPath, kLogoutIndexPath]
    ]
    
    //var delegate: MenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if User.currentUser()?.facebookId == nil {
//            
//            data = [
//                [kProfileIndexPath, kLogoutIndexPath]
//            ]
//        }
        
        setupTableView(tableView, delegate: self, dataSource: self)
        
        addCloseButton()
        
        title = "Settings"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        //deselectSelectedCell(tableView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //delegate?.menuDidClose()
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
                    
                    //remove user from installation
                    let installation = PFInstallation.currentInstallation()
                    installation.removeObjectForKey(kParseInstallationUserKey)
                    installation.save()
                    
                    User.logOutInBackgroundWithBlock({ (error) -> Void in
                        
                        if let error = error {
                            
                            ParseUtilities.showAlertWithErrorIfExists(error)
                        }
                        else {

                            let v = UIStoryboard.initialViewControllerFromStoryboardNamed("Login")
                            self.presentViewController(v, animated: true, completion: nil)
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
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == kProfileSection {
            
            return "Logged in as \(User.currentUser()!.appropriateDisplayName())"
        }
        
        return ""
    }
}

