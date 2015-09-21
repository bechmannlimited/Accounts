//
//  FindFriendsViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 21/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit
import Parse

class FindFriendsViewController: BaseViewController {

    var tableView = UITableView()
    var matches = [User]()
    var searchController = UISearchController(searchResultsController: nil)
    var matchesQuery: PFQuery?
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add friend"
        
        setupTableView(tableView, delegate: self, dataSource: self)
        tableView.allowsSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        
        setupSearchController()
    }
    
    func setupSearchController() {
        
        let searchBar = searchController.searchBar
        
        searchController.delegate = self
        searchBar.delegate = self

        tableView.tableHeaderView = searchBar
        searchBar.sizeToFit()

        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchBar.tintColor = kNavigationBarTintColor
    }
    
    func getMatches(searchText: String) {
        
        timer?.invalidate()
        
        let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        loadingView.showLoader()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingView)
        
        //timer = NSTimer.scheduledTimerWithTimeInterval(4000, target: self, selector: "", userInfo: nil, repeats: false)
        
        self.timer = NSTimer.schedule(delay: 2.5, handler: { timer in
            
            //self.timer = timer
            
            self.matchesQuery?.cancel()
            
            self.matchesQuery = PFQuery.orQueryWithSubqueries([
                User.query()!.whereKey(kParse_User_Username_Key, matchesRegex: "^\(searchText)$", modifiers: "i"),
                User.query()!.whereKey(kParse_User_DisplayName_Key, matchesRegex: "^\(searchText)$", modifiers: "i")
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
            print("hi")
            self.matchesQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                print("hi2")
                if var matches = objects as? [User] {
                    
                    //remove match if already in invite pool
                    for match in matches {
                        
                        for invite in User.currentUser()!.allInvites[0] {
                            
                            if invite.fromUser?.objectId == match.objectId {
                                
                                let index = find(matches, match)!
                                matches.removeAtIndex(index)
                            }
                        }
                        for invite in User.currentUser()!.allInvites[1] {
                            
                            if invite.toUser?.objectId == match.objectId {
                                
                                let index = find(matches, match)!
                                matches.removeAtIndex(index)
                            }
                        }
                        for friend in User.currentUser()!.friends {
                            
                            if friend.objectId == match.objectId {
                                
                                let index = find(matches, match)!
                                matches.removeAtIndex(index)
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
    
    func addFriend(match:User) {
        
        searchController.active = false
        searchController.searchBar.userInteractionEnabled = false
        
        User.currentUser()?.sendFriendRequest(match, completion: { (success) -> () in
            
            if success {
                
                UIAlertView(title: "Invitation sent!", message: "Please wait for your invite to be accepted!", delegate: nil, cancelButtonTitle: "OK").show()
                self.searchController.searchBar.text = ""
                self.matches = []
                self.tableView.reloadData()
            }
            else {
                
                UIAlertView(title: "Oops!", message: "Something went wrong!", delegate: self, cancelButtonTitle: "OK").show()
            }
            
            User.currentUser()?.getInvites({ (invites) -> () in
                
                self.searchController.searchBar.userInteractionEnabled = true
            })
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        searchController.searchBar.removeFromSuperview()
        searchController.delegate = nil
    }
}

extension FindFriendsViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        
        cell.textLabel?.text = match.appropriateDisplayName()
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
}