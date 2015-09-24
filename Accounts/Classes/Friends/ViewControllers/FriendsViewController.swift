//
//  FriendsViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 05/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import Parse
import SwiftyJSON

private let kPlusImage = AppTools.iconAssetNamed("746-plus-circle-selected.png")
private let kMinusImage = AppTools.iconAssetNamed("34-circle.minus.png")
private let kMenuIcon = AppTools.iconAssetNamed("740-gear-toolbar")

private let kPopoverContentSize = CGSize(width: 320, height: 360)

class FriendsViewController: ACBaseViewController {
    
    var tableView = UITableView(frame: CGRectZero, style: kDevice == .Pad ? .Grouped : .Plain)
    
    var addBarButtonItem: UIBarButtonItem?
    var friendInvitesBarButtonItem: UIBarButtonItem?
    var openMenuBarButtonItem: UIBarButtonItem?
    
    var popoverViewController: UIViewController?
    
    var isLoading = false
    var data: Array<Array<User>> = [[],[],[]]
    
    var invitesCount = 0
    var hasCheckedForInvites = false
    
    var refreshBarButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView(tableView, delegate: self, dataSource: self)
        setBarButtonItems()
        
        title = "Friends"
        view.showLoader()
        
        if kDevice == .Pad {
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        let text = User.currentUser()?.facebookId != nil ? "Your Facebook friends who have this app, will appear here!" : "Tap settings and send a friend invite to get started!"
        setupNoDataLabel(noDataView, text: text, originView: tableView) //To get started, invite some friends!
        setupTextLabelForSaveStatusInToolbarWithLabel()
        setupToolbar()
        
        //tableView.layer.opacity = 0
        view.showLoader()
        
        refreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refreshFromBarButton")
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            refreshBarButtonItem!
        ]
        
        if User.currentUser()?.lastSyncedDataInfo == nil {
            
            User.currentUser()?.lastSyncedDataInfo = Dictionary<String, NSDate>()
        }
        
        if let lastSyncedDate = User.currentUser()?.lastSyncedDataInfo?["Friends_\(User.currentUser()!.objectId!)"] {
            
            self.refreshUpdatedDate = lastSyncedDate
        }
        
        tableView.separatorColor = .clearColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refresh(nil)
        setEditing(false, animated: false)
        
        if let indexPath = tableView.indexPathForSelectedRow() {
            
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        AppDelegate.registerForNotifications()
    }
    
    override func didReceivePushNotification(notification: NSNotification) {
        
        println(notification.object)
        
        if let object: AnyObject = notification.object{
            
            let value = JSON(notification.object![kPushNotificationTypeKey]!!).intValue
            
            if PushNotificationType(rawValue: value) == PushNotificationType.FriendRequestAccepted || PushNotificationType(rawValue: value) == PushNotificationType.ItemSaved {
                
                refresh(nil)
            }
            else if PushNotificationType(rawValue: value) == PushNotificationType.FriendRequestSent || PushNotificationType(rawValue: value) == PushNotificationType.FriendRequestDeleted {
                    
                //getInvites()
            }
        }
    }
    
    override func setupView() {
        super.setupView()
        
        view.backgroundColor = colorForViewBackground()
    }
    
    func colorForViewBackground() -> UIColor {

        return kDevice == .Phone ? UIColor.whiteColor() : kViewBackgroundColor
    }
    
    func setupToolbar(){
        
        toolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
        toolbar.sizeToFit()
        view.addSubview(toolbar)
        
        toolbar.addHeightConstraint(relation: .Equal, constant: toolbar.frame.height)
        toolbar.addLeftConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addRightConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        if var height = navigationController?.navigationBar.frame.height {
            
            if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) {
                
                height += UIApplication.sharedApplication().statusBarFrame.height
                tableView.contentInset = UIEdgeInsets(top: height, left: tableView.contentInset.left, bottom: tableView.contentInset.bottom, right: tableView.contentInset.right)
            }
        }
        
        var previousInsets = tableView.contentInset
        tableView.contentInset = UIEdgeInsets(top: previousInsets.top, left: previousInsets.left, bottom: previousInsets.bottom + toolbar.frame.height, right: previousInsets.right)
        
        toolbar.tintColor = kNavigationBarTintColor
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
        
        if view.bounds.width >= kTableViewMaxWidth {
            
            //tableView.reloadData()
        }
        
        if data[2].count > 0 && editing {
            
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2), atScrollPosition: .Top, animated: true)
        }
    }
    
    func setBarButtonItems() {
        
        var emptyBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        emptyBarButtonItem.width = 0
        
        addBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add")
        
        
        let invitesText = invitesCount > 0 ? "Invites (\(invitesCount))" : "Invites"
        
        friendInvitesBarButtonItem = UIBarButtonItem(title: invitesText, style: .Plain, target: self, action: "friendInvites")
        openMenuBarButtonItem = UIBarButtonItem(image: kMenuIcon, style: .Plain, target: self, action: "openMenu")
        
        let editBarButtonItem = editButtonItem() //data[2].count > 0 ? editButtonItem() : UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        
        navigationItem.leftBarButtonItems = [
            openMenuBarButtonItem!
            //editBarButtonItem
        ]
        navigationItem.rightBarButtonItems = [
            //friendInvitesBarButtonItem!
        ]
    }
    
    func showOrHideAddButton() {
        
        if let addBtn = addBarButtonItem{
            
            navigationItem.rightBarButtonItems = [
                //UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
                addBtn
                //UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            ]
        }
        else{
            
            navigationItem.rightBarButtonItems = []
        }
        
        addBarButtonItem?.enabled = User.currentUser()!.friends.count > 0
    }
    
    func friendInvites() {
        
        let view = FriendInvitesViewController()
        view.delegate = self
        let v = UINavigationController(rootViewController: view)
        
        v.modalPresentationStyle = .Popover
        v.preferredContentSize = kPopoverContentSize
        v.popoverPresentationController?.barButtonItem = friendInvitesBarButtonItem
        v.popoverPresentationController?.delegate = self
        
        presentViewController(v, animated: true, completion: nil)
    }
    
    func setDataForTable() {
        
        var rc = Array<Array<User>>()
        
        var friendsWhoOweMoney = Array<User>()
        var friendsWhoYouOweMoney = Array<User>()
        var friendsWhoAreEven = Array<User>()
            
        //owes you money
        for friend in User.currentUser()!.friends {
            
            if friend.localeDifferenceBetweenActiveUser.roundToPlaces(2) < 0 {
                
                friendsWhoOweMoney.append(friend)
            }
        }
        
        for friend in User.currentUser()!.friends {
            
            if friend.localeDifferenceBetweenActiveUser.roundToPlaces(2) > 0 {
                
                friendsWhoYouOweMoney.append(friend)
            }
        }
        
        for friend in User.currentUser()!.friends {

            if friend.localeDifferenceBetweenActiveUser.roundToPlaces(2) == 0 {
                
                friendsWhoAreEven.append(friend)
            }
        }
        
        data = [friendsWhoOweMoney, friendsWhoYouOweMoney, friendsWhoAreEven]
    }
    
    override func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        setupTableViewRefreshControl(tableView)
    }
    
    override func refresh(refreshControl: UIRefreshControl?) {
        
        refreshBarButtonItem?.enabled = false
        
        NSTimer.schedule(delay: 10, handler: { timer in
            
            refreshBarButtonItem?.enabled = true
        })
        
        User.currentUser()?.getFriends({ (completedRemoteRequest) -> () in
            
            refreshControl?.endRefreshing()
            self.setDataForTable()
            self.tableView.reloadData()
            self.view.hideLoader()
            self.showOrHideAddButton()
            self.showOrHideTableOrNoDataView()
            
            if completedRemoteRequest {
                
                User.currentUser()?.lastSyncedDataInfo?["Friends_\(User.currentUser()!.objectId!)"] = NSDate()
                self.refreshUpdatedDate = NSDate()
                self.refreshBarButtonItem?.enabled = true
            }
        })
        
        //getInvites()
    }
    
    func refreshFromBarButton(){
        
        refresh(nil)
    }
    
    func openMenu() {
        
        let view = MenuViewController()
        //view.delegate = self
        
        let v = UINavigationController(rootViewController:view)
        v.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        presentViewController(v, animated: true, completion: nil)
    }
    
    func add() {
        
        if User.currentUser()?.friends.count > 0 {
            
            let view = SelectPurchaseOrTransactionViewController()
            let v = UINavigationController(rootViewController: view)
            view.saveItemDelegate = self
            
            v.modalPresentationStyle = .Popover
            v.preferredContentSize = kPopoverContentSize
            v.popoverPresentationController?.barButtonItem = addBarButtonItem
            v.popoverPresentationController?.delegate = self
            
            presentViewController(v, animated: true, completion: nil)
        }
        else{
            
            UIAlertController.showAlertControllerWithButtonTitle("Ok", confirmBtnStyle: .Default, message: "You havn't added any friends yet!", completion: { (response) -> () in
                
                
            })
        }
    }
    
    func showOrHideTableOrNoDataView() {
        
        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
            
            self.noDataView.layer.opacity = User.currentUser()!.friends.count > 0 ? 0 : 1
            self.view.backgroundColor = User.currentUser()!.friends.count > 0 ? self.colorForViewBackground() : kViewBackgroundColor
            self.tableView.separatorColor = User.currentUser()!.friends.count > 0 ? kTableViewSeparatorColor : .clearColor()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        Task.sharedTasker().cancelTaskForIdentifier("GetFriends")
    }
}

extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return data.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = FriendTableViewCell(reuseIdentifier: "Cell");
        
        let friend = data[indexPath.section][indexPath.row]
        (cell as FriendTableViewCell).setup(friend)
        (cell as FriendTableViewCell).delegate = self
        (cell as FriendTableViewCell).currentIndexPath = indexPath
        
        //cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        //cell.layer.shouldRasterize = true
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let friend = data[indexPath.section][indexPath.row]
        
        var v = TransactionsViewController()
        v.friend = friend
        navigationController?.pushViewController(v, animated: true)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if data[section].count > 0 {
            
            if section == 0 {
                
                return "People I owe"
            }
            else if section == 1 {
                
                return "People who owe me"
            }
            else if section == 2 {
                
                return "People I'm even with"
            }
        }
        
        return ""
    }
    
//    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        
//        if section == numberOfSectionsInTableView(tableView) - 1 && User.currentUser()?.friends.count > 0 && User.currentUser()?.friends.count < 2 {
//            
//            return "Your Facebook friends who have this app, will appear here!"
//        }
//        
//        return nil
//    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return tableView.editing ? .Delete : .None
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let friend = data[indexPath.section][indexPath.row]
        
        return indexPath.section == 2 && friend.facebookId == nil
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let friend = data[indexPath.section][indexPath.row]
        
        UIAlertController.showAlertControllerWithButtonTitle("Delete", confirmBtnStyle: .Destructive, message: "Are you sure you want to remove \(friend.appropriateDisplayName()) as a friend?") { (response) -> () in
            
            if response == .Confirm {
                
                tableView.beginUpdates()
                
                self.data[indexPath.section].removeAtIndex(indexPath.row)
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
                tableView.endUpdates()
                
                User.currentUser()?.removeFriend(friend, completion: { (success) -> () in

                    self.refresh(nil)
                })
            }
            else {
                
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return 70
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        return data[section].count > 0 ? 35 : 0
    }
}

extension FriendsViewController: UIPopoverPresentationControllerDelegate {
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        
        popoverViewController = nil
        refresh(nil)
    }
    
    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        
        if let viewController = popoverViewController as? SavePurchaseViewController {
            
            viewController.askToPopIfChanged() // popall
            return false
        }
        else if let viewController = popoverViewController as? SaveTransactionViewController {
            
            viewController.askToPopIfChanged() // popall
            return false
        }
        else {
            
            return true
        }
    }
}

extension FriendsViewController: FriendInvitesDelegate {
    
    func friendsChanged() {
        
        refresh(nil)
    }
}

extension FriendsViewController: SaveItemDelegate {
    
    func itemDidGetDeleted() {

    }
    
    func itemDidChange() {
        
        
    }
    
    func transactionDidChange(transaction: Transaction) {
        

    }
    
    func purchaseDidChange(purchase: Purchase) {
        

    }
    
    func newItemViewControllerWasPresented(viewController: UIViewController?) {
        
        popoverViewController = viewController
    }
    
    func dismissPopover() {
        
        
    }
}

extension FriendsViewController: FriendTableViewCellDelegate {
    
    func didRemoveFriend(friend: User, indexPath: NSIndexPath?) {
        
        if let indexPath = indexPath {
            
            tableView.beginUpdates()
            //User.currentUser()?.friends.removeAtIndex(find(User.currentUser()!.friends, friend)!)
            data[indexPath.section].removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
            tableView.endUpdates()
        }
        
        NSTimer.schedule(delay: 0.5, handler: { timer in
        
            self.refresh(nil)
        })
    }
}