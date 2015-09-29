//
//  FindFriendsViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 21/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
 
import Parse
import SwiftOverlays

class FindFriendsViewController: ACBaseViewController {

    var tableView = UITableView()
    var matches = [User]()
    //var searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()
    var matchesQuery: PFQuery?
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add friend"
        
        setupTableView(tableView, delegate: self, dataSource: self)
        tableView.allowsSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        
        setupSearchBar()
    }
    
//    func setupSearchController() {
//        
//        let searchBar = searchController.searchBar
//        
//        searchController.delegate = self
//        searchBar.delegate = self
//
//        tableView.tableHeaderView = searchBar
//        searchBar.sizeToFit()
//
//        searchController.dimsBackgroundDuringPresentation = false
//        searchController.hidesNavigationBarDuringPresentation = false
//        
//        searchBar.tintColor = kNavigationBarTintColor
//    }
    func setupSearchBar() {
        
        searchBar.delegate = self
        
        searchBar.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        //navigationController?.navigationBar.addSubview(searchBar)
        tableView.tableHeaderView = searchBar
        searchBar.sizeToFit()
        
        searchBar.tintColor = kNavigationBarTintColor
        searchBar.placeholder = "Search for a user"
    }
    
    override func appDidResume() {
        //super.appDidResume()
        
        getMatches(searchBar.text!)
    }
    
    func getMatches(searchText: String) {
        
        timer?.invalidate()
        
        let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        loadingView.showLoader()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingView)
        
        self.matchesQuery?.cancel()
        
        if searchText.characterCount() > 0 {
            
            self.timer = NSTimer.schedule(delay: 2.5, handler: { timer in
                
                self.matchesQuery = PFQuery.orQueryWithSubqueries([
                    User.query()!.whereKey(kParse_User_Username_Key, matchesRegex: "^\(searchText)$", modifiers: "i"),
                    User.query()!.whereKey(kParse_User_DisplayName_Key, matchesRegex: "^\(searchText)$", modifiers: "i"),
                    User.query()!.whereKey("email", matchesRegex: "^\(searchText)$", modifiers: "i")
                    ])
                
                self.matchesQuery?.whereKey("objectId", notEqualTo: User.currentUser()!.objectId!)
                
                for invite in User.currentUser()!.allInvites[0] {
                    
                    self.matchesQuery?.whereKey(kParse_User_Friends_Key, notEqualTo: invite.toUser!)
                    self.matchesQuery?.whereKey(kParse_User_Friends_Key, notEqualTo: invite.fromUser!)
                }
                for invite in User.currentUser()!.allInvites[1] {
                    
                    self.matchesQuery?.whereKey(kParse_User_Friends_Key, notEqualTo: invite.toUser!)
                    self.matchesQuery?.whereKey(kParse_User_Friends_Key, notEqualTo: invite.fromUser!)
                }
                
                self.matchesQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                    
                    if var matches = objects as? [User] {
                        
                        //remove match if already in invite pool
                        for match in matches {
                            
                            for invite in User.currentUser()!.allInvites[0] {
                                
                                if invite.fromUser?.objectId == match.objectId {
                                    
                                    if let index = find(matches, match) {
                                        
                                        matches.removeAtIndex(index)
                                    }
                                }
                            }
                            for invite in User.currentUser()!.allInvites[1] {
                                
                                if invite.toUser?.objectId == match.objectId {
                                    
                                    if let index = find(matches, match) {
                                        
                                        matches.removeAtIndex(index)
                                    }
                                }
                            }
                            for friend in User.currentUser()!.friends {
                                
                                if friend.objectId == match.objectId {
                                    
                                    if let index = find(matches, match) {
                                        
                                        matches.removeAtIndex(index)
                                    }
                                }
                            }
                        }
                        
                        self.matches = matches
                    }
                    
                    self.tableView.reloadData()
                    self.navigationItem.rightBarButtonItem = nil
                })
            })
        }
    }
    
    func addFriend(match:User) {
        
        //searchController.active = false
        view.endEditing(true)
        searchBar.userInteractionEnabled = false
        
        SwiftOverlays.showBlockingWaitOverlayWithText("Adding friend...")
        
        User.currentUser()?.sendFriendRequest(match, completion: { (success) -> () in
            
            if success {
                
                UIAlertView(title: "Invitation sent!", message: "Please wait for your invite to be accepted!", delegate: nil, cancelButtonTitle: "OK").show()
                self.searchBar.text = ""
                self.matches = []
                self.tableView.reloadData()
            }
            else {
                
                UIAlertView(title: "Oops!", message: "Something went wrong!", delegate: self, cancelButtonTitle: "OK").show()
            }
            
            SwiftOverlays.removeAllBlockingOverlays()
            
            User.currentUser()?.getInvites({ (invites) -> () in
                
                self.searchBar.userInteractionEnabled = true
            })
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        //searchBar.removeFromSuperview()
        searchBar.delegate = nil
    }
}

extension FindFriendsViewController {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return matches.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: .Value1, reuseIdentifier: identifier)
        })
        
        let match = matches[indexPath.row]
        
        var text = ""
    
        if match.facebookId != nil {
            
            text = match.appropriateDisplayName()
        }
        else{
            
            text = "\(String.emptyIfNull(match.username))"
            
            if match.displayName?.isEmpty == false {
                
                text = "\(String.emptyIfNull(match.username)) (\(String.emptyIfNull(match.displayName)))"
            }
        }
        
        cell.textLabel?.text = text
        
        cell.detailTextLabel?.text = "Add as friend"
        cell.detailTextLabel?.textColor = AccountColor.greenColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return UITableViewCellEditingStyle.Insert
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let user = matches[indexPath.row]
        addFriend(user)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let user = matches[indexPath.row]
        addFriend(user)
    }
}

extension FindFriendsViewController: UISearchControllerDelegate, UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        getMatches(searchText)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        getMatches(searchBar.text)
    }
}