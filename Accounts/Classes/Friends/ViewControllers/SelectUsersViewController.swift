//
//  SelectFriendsViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
 


protocol SelectUsersDelegate {
    
    func didSelectUsers(users: Array<User>, identifier: String)
}

protocol SelectUserDelegate {
    
    func didSelectUser(user: User, identifier: String)
}

class SelectUsersViewController: ACBaseViewController {

    var tableView = UITableView()
    var selectUsersDelegate: SelectUsersDelegate?
    var selectUserDelegate: SelectUserDelegate?
    var userIsSelected = Dictionary<String, Bool>()
    var allowEditing = false
    var allowMultipleSelection = false
    var identifier = ""
    var isInsidePopover = false
    
    var users: Array<User> = []
    
    convenience init(identifier: String, users:Array<User>, selectUsersDelegate: SelectUsersDelegate?, allowEditing: Bool, usersToChooseFrom: Array<User>, isInsidePopover: Bool) {
        self.init()
        
        self.identifier = identifier
        self.selectUsersDelegate = selectUsersDelegate
        self.allowEditing = allowEditing
        self.allowMultipleSelection = true
        self.users = usersToChooseFrom
        self.isInsidePopover = isInsidePopover
        
        setSelectedUsers(users)
    }
    
    convenience init(identifier: String, user:User?, selectUserDelegate: SelectUserDelegate?, allowEditing: Bool, usersToChooseFrom: Array<User>, isInsidePopover: Bool) {
        self.init()
        
        self.identifier = identifier
        self.selectUserDelegate = selectUserDelegate
        self.allowEditing = allowEditing
        self.allowMultipleSelection = false
        self.users = usersToChooseFrom
        self.isInsidePopover = isInsidePopover
        
        if let user = user {
            
            setSelectedUser(user)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if kDevice == .Pad && !isInsidePopover {
            
            tableView = UITableView(frame: CGRectZero, style: .Grouped)
        }
        
        setupTableView(tableView, delegate: self, dataSource: self)
        setupTableViewRefreshControl(tableView)
        
        if allowMultipleSelection {

            if allowEditing {
                
                title = "Select users"
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done")
            }
            else {
                
                title = "Users"
            }
        }
        else {
            
            if allowEditing {
                
                title = "Select user"
            }
            else {
                
                title = "User"
            }
        }
    }
    
    override func setupTableViewRefreshControl(tableView: UITableView) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refresh(nil)
        
        if kDevice == .Pad && !isInsidePopover {
            
            tableView.separatorColor = .clearColor()
        }
        else {
            
            tableView.backgroundColor = UIColor.whiteColor()
        }
        
    }
    
    override func refresh(refreshControl: UIRefreshControl?) {
        
//        kActiveUser.getFriends().onDownloadFinished({ () -> () in
//            
//            refreshControl?.endRefreshing()
//            self.tableView.reloadData()
//            
//        }).onDownloadFailure({ (error, alert) -> () in
//            
//            alert.show()
//        })
        
        //refreshControl?.endRefreshing()
    }
    
    func done() {
        
        var selectedUsers = Array<User>()
        
        for values in userIsSelected {
            
            for user in users {
                
                if user.objectId == values.0 {
                    
                    selectedUsers.append(user)
                }
            }
        }
        
        selectUsersDelegate?.didSelectUsers(selectedUsers, identifier: identifier)
        close()
    }

    override func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    func setSelectedUsers(users: Array<User>) {
        
        for user in users {
            
            userIsSelected[user.objectId!] = true
        }
    }
    
    func setSelectedUser(user: User) {
        
        setSelectedUsers([user])
    }
}

extension SelectUsersViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return users.count// + 1 // for active user
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
        
        let user = users[indexPath.row]
//        
//        if indexPath.row == kActiveUser.friends.count - 1 {
//            
//            friend = kActiveUser.friends[indexPath.row]
//        }
//        else {
//            
//            friend = kActiveUser
//        }
        
        cell.textLabel?.text = user.appropriateDisplayName()
        
        var selected = false
        
        if let s = userIsSelected[user.objectId!] {
            
            selected = s
        }
        
        cell.accessoryType = selected ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        deselectSelectedCell(tableView)
        
        if allowEditing {
            
            let user = users[indexPath.row]
            
            if allowMultipleSelection {
                
                if let _ = userIsSelected[user.objectId!] {
                    
                    userIsSelected.removeValueForKey(user.objectId!)
                }
                else {
                    
                    userIsSelected[user.objectId!] = true
                }
                
                tableView.reloadData()
            }
            else {
                
                selectUserDelegate?.didSelectUser(user, identifier: identifier)
                close()
            }
        }
    }
}