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
private let kMenuIcon = AppTools.iconAssetNamed("740-gear-toolbar-selected.png")
//private let kFriendInvitesIcon = AppTools.iconAssetNamed("779-users-selected.png")
private let kAnimationDuration:NSTimeInterval = 0.5

private let kPopoverContentSize = CGSize(width: 320, height: 360)

class FriendsViewController: ACBaseViewController {
    
    var tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
    
    var addBarButtonItem: UIBarButtonItem?
    var friendInvitesBarButtonItem: UIBarButtonItem?
    var openMenuBarButtonItem: UIBarButtonItem?
    var noDataView = UILabel()
    
    var popoverViewController: UIViewController?
    var toolbar = UIToolbar()
    
    var isLoading = false
    var data: Array<Array<User>> = [[],[],[]]
    
    var invitesCount = 0
    var hasCheckedForInvites = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if kDevice == .Phone {
            
            tableView = UITableView(frame: CGRectZero, style: .Grouped)
        }
        
        setupTableView(tableView, delegate: self, dataSource: self)
        //tableView.separatorColor = UIColor.clearColor()
        setBarButtonItems()
        
        title = "Friends"
        view.showLoader()
        
        if kDevice == .Pad {
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        setupNoDataLabel(noDataView, text: "To get started, click invites to add some friends!")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refresh(nil)
        setEditing(false, animated: false)
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
                    
                getInvites()
            }
        }
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
        
        addBarButtonItem = User.currentUser()!.friends.count > 0 ? UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add") : emptyBarButtonItem
        
        
        let invitesText = invitesCount > 0 ? "Invites (\(invitesCount))" : "Invites"
        
        friendInvitesBarButtonItem = UIBarButtonItem(title: invitesText, style: .Plain, target: self, action: "friendInvites")
        openMenuBarButtonItem = UIBarButtonItem(image: kMenuIcon, style: .Plain, target: self, action: "openMenu")
        
        let editBarButtonItem = data[2].count > 0 ? editButtonItem() : UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        
        navigationItem.leftBarButtonItems = [
            openMenuBarButtonItem!,
            editBarButtonItem
        ]
        navigationItem.rightBarButtonItems = [
            addBarButtonItem!,
            friendInvitesBarButtonItem!
        ]
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
            
            if friend.localeDifferenceBetweenActiveUser < 0 {
                
                friendsWhoOweMoney.append(friend)
            }
        }
        
        for friend in User.currentUser()!.friends {
            
            if friend.localeDifferenceBetweenActiveUser > 0 {
                
                friendsWhoYouOweMoney.append(friend)
            }
        }
        
        for friend in User.currentUser()!.friends {
            
            if friend.localeDifferenceBetweenActiveUser == 0 {
                
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
        
        view.showLoader()
        tableView.layer.opacity = 0
        
        User.currentUser()?.getFriends({ () -> () in
            
            refreshControl?.endRefreshing()
            self.setDataForTable()
            self.tableView.reloadData()
            self.view.hideLoader()
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                
                self.tableView.layer.opacity = 1
            })
            
            self.setBarButtonItems()
            self.showOrHideTableOrNoDataView()
        })
        
        getInvites()
    }
    
    func getInvites(){
        
        User.currentUser()?.getInvites({ (invites) -> () in
            
            self.hasCheckedForInvites = true
            self.invitesCount = invites[0].count
            self.setBarButtonItems()
        })
    }
    
    func openMenu() {
        
        let view = MenuViewController()
        //view.delegate = self
        
        let v = UINavigationController(rootViewController:view)
        v.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        presentViewController(v, animated: true, completion: nil)
    }
    
    func add() {
        
        let view = SelectPurchaseOrTransactionViewController()
        let v = UINavigationController(rootViewController: view)
        view.saveItemDelegate = self

        v.modalPresentationStyle = .Popover
        v.preferredContentSize = kPopoverContentSize
        v.popoverPresentationController?.barButtonItem = addBarButtonItem
        v.popoverPresentationController?.delegate = self
        
        presentViewController(v, animated: true, completion: nil)
    }
    
    func showOrHideTableOrNoDataView() {
        
        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
            
            self.noDataView.layer.opacity = User.currentUser()!.friends.count > 0 ? 0 : 1
            self.tableView.layer.opacity = User.currentUser()!.friends.count > 0 ? 1 : 1
            self.tableView.separatorColor = User.currentUser()!.friends.count > 0 ? kDefaultSeperatorColor : .clearColor()
        })
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
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: identifier)
        })
        
        cell.backgroundColor = UIColor.whiteColor()
        //setTableViewCellAppearanceForBackgroundGradient(cell)
        
        let friend = data[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = friend.appropriateDisplayName()
        let amount = friend.localeDifferenceBetweenActiveUser //abs()
        
        var tintColor = UIColor.lightGrayColor()
        
        if friend.localeDifferenceBetweenActiveUser < 0 {
            
            tintColor = AccountColor.negativeColor()
        }
        else if friend.localeDifferenceBetweenActiveUser > 0 {
            
            tintColor = AccountColor.positiveColor()
        }
        
        //cell.imageView?.image = friend.localeDifferenceBetweenActiveUser < 0 ? kMinusImage : kPlusImage
        //cell.imageView?.tintWithColor(tintColor)
        
        cell.detailTextLabel?.text = Formatter.formatCurrencyAsString(amount)
        cell.detailTextLabel?.textColor = tintColor
        //cell.editingAccessoryType = UITableViewCellAccessoryType.DisclosureIndicator;
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        //images
        let imageWidth = 50
        cell.imageView?.image = AppTools.iconAssetNamed("769-male-selected.png")
        cell.imageView?.layer.cornerRadius = cell.imageView!.image!.size.width / 2
        cell.imageView?.tintWithColor(tintColor)
        cell.imageView?.clipsToBounds = true
        
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
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return tableView.editing ? .Delete : .None
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return indexPath.section == 2
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

        return data[section].count > 0 ? UITableViewAutomaticDimension : CGFloat.min
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let numberOfRowsInSections:Int = tableView.numberOfRowsInSection(indexPath.section)
        
        cell.layer.mask = nil
        
        var shouldRoundCorners = view.bounds.width > kTableViewMaxWidth
        
        if tableView.editing && shouldRoundCorners {
            
            shouldRoundCorners = indexPath.section != 2
        }
        
        if shouldRoundCorners {
            
            if indexPath.row == 0 {
                
                cell.roundCorners(UIRectCorner.TopLeft | UIRectCorner.TopRight, cornerRadiusSize: kTableViewCellIpadCornerRadiusSize)
            }
            
            if indexPath.row == numberOfRowsInSections - 1 {
                
                cell.roundCorners(UIRectCorner.BottomLeft | UIRectCorner.BottomRight, cornerRadiusSize: kTableViewCellIpadCornerRadiusSize)
            }
            
            if indexPath.row == 0 && indexPath.row == numberOfRowsInSections - 1 {
                
                cell.roundCorners(UIRectCorner.AllCorners, cornerRadiusSize: kTableViewCellIpadCornerRadiusSize)
            }
        }
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

//extension FriendsViewController: MenuDelegate {
//    
//    func menuDidClose() {
//        
//        refresh(nil)
//    }
//}

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