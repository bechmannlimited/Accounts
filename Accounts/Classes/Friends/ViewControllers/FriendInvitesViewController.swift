//
//  FriendInvitesViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 20/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit

private let kUnconfirmedInvitesSection = 0
private let kUnconfirmedSentInvitesSection = 1
private let kAnimationDuration:NSTimeInterval = 0.5

protocol FriendInvitesDelegate {
    
    func friendsChanged()
}

class FriendInvitesViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    var invites:Array<Array<FriendRequest>> = []
    var delegate: FriendInvitesDelegate?
    var noDataView = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Friend invites"
        
        setupTableView(tableView, delegate: self, dataSource: self)
        setupTableViewRefreshControl(tableView)
        tableView.allowsSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        
        addCloseButton()
        view.showLoader()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "findFriends")
        
        setupNoDataLabel(noDataView, text: "Tap plus to send someone a friend invitation")
    }
    
    func showOrHideTableOrNoDataView() {
        
        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
            
            var count = 0
            
            for arr in self.invites {
                
                for invite in arr {
                    
                    count++
                }
            }
            
            self.noDataView.layer.opacity = count > 0 ? 0 : 1
            self.tableView.layer.opacity = count > 0 ? 1 : 1
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if isInsidePopover() {
            
            navigationController?.view.backgroundColor = UIColor.clearColor()
            view.backgroundColor = UIColor.clearColor()
            tableView.backgroundColor = UIColor.clearColor()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        refresh(nil)
    }

    override func refresh(refreshControl: UIRefreshControl?) {
        
        User.currentUser()?.getInvites({ (invites) -> () in
            
            self.invites = invites
            
            self.tableView.reloadData()
            refreshControl?.endRefreshing()
            self.view.hideLoader()
            self.showOrHideTableOrNoDataView()
        })
    }
    
    func findFriends() {
        
        navigationController?.pushViewController(FindFriendsViewController(), animated: true)
    }
}

extension FriendInvitesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return invites.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return invites[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: .Value1, reuseIdentifier: identifier)
        })
        
        var user: User?
        
        if indexPath.section == kUnconfirmedInvitesSection {
            
            user = invites[indexPath.section][indexPath.row].fromUser
        }
        else if indexPath.section == kUnconfirmedSentInvitesSection {
            
            user = invites[indexPath.section][indexPath.row].toUser
        }

        cell.textLabel?.text = user!.username
        
        if indexPath.section == kUnconfirmedInvitesSection {
            
            cell.detailTextLabel?.text = "Accept invite"
            cell.detailTextLabel?.textColor = AccountColor.greenColor()
        }
        
        else {
            
            cell.detailTextLabel?.text = "Pending"
            cell.detailTextLabel?.textColor = UIColor.lightGrayColor()
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let friendRequest = invites[indexPath.section][indexPath.row]
        let user = friendRequest.fromUser!
        
        if indexPath.section == kUnconfirmedInvitesSection {
            
            User.currentUser()?.addFriendFromRequest(friendRequest, completion: { (success) -> () in
                
                self.refresh(nil)
                self.delegate?.friendsChanged()
            })
        }
        
        if indexPath.section == kUnconfirmedSentInvitesSection {
            
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
            invites[indexPath.section].removeAtIndex(indexPath.row)
            tableView.endUpdates()
            
            friendRequest.deleteInBackgroundWithBlock({ (success, error) -> Void in
                
                println(success)
                println(error)
                self.refresh(nil)
            })
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if invites[section].count > 0 {
            
            if section == 0 {
                
                return "Invites received"
            }
            if section == 1 {
                
                return "Invites sent"
            }
        }
        
        return ""
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return indexPath.section == kUnconfirmedInvitesSection ? UITableViewCellEditingStyle.Insert : .Delete
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.delegate?.tableView?(tableView, didSelectRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return invites[section].count > 0 ? UITableViewAutomaticDimension : CGFloat.min
    }
}