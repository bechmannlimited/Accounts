//
//  FriendsViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 05/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
 
import Parse
import SwiftyJSON

private let kPlusImage = AppTools.iconAssetNamed("746-plus-circle-selected.png")
private let kMinusImage = AppTools.iconAssetNamed("34-circle.minus.png")
private let kMenuIcon = AppTools.iconAssetNamed("740-gear-toolbar")

private let kPopoverContentSize = CGSize(width: 320, height: 360)

class FriendsViewController: ACBaseViewController {
    
    //var tableView = UITableView(frame: CGRectZero, style: kDevice == .Pad ? .Grouped : .Plain)
    var collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    
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
        
        //setupTableView(tableView, delegate: self, dataSource: self)
        setupCollectionView()
        setBarButtonItems()
        
        title = "Friends"
        view.showLoader()
        
//        if kDevice == .Pad {
//            
//            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
//        }
        
        let text = User.currentUser()?.facebookId != nil ? "Your Facebook friends who have this app, will appear here!" : "Tap settings and send a friend invite to get started!"
        setupNoDataLabel(noDataView, text: text, originView: collectionView) //To get started, invite some friends!
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
        
        //tableView.separatorColor = .clearColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refresh(nil)
//        setEditing(false, animated: false)
//        
//        if let indexPath = tableView.indexPathForSelectedRow {
//            
//            tableView.deselectRowAtIndexPath(indexPath, animated: false)
//        }
    }
    
    private var hasAskedForPreferredCurrency = false
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        AppDelegate.registerForNotifications()
        
        if !hasAskedForPreferredCurrency {
            
            askForPreferredCurrencyIfNotSet()
            hasAskedForPreferredCurrency = true
        }
    }
    
    override func didReceivePushNotification(notification: NSNotification) {
        
        if let object: AnyObject = notification.object{
            
            let value = JSON(object[kPushNotificationTypeKey]!!).intValue
            
            if PushNotificationType(rawValue: value) == PushNotificationType.FriendRequestAccepted || PushNotificationType(rawValue: value) == PushNotificationType.ItemSaved {
                
                refresh(nil)
            }
            else if PushNotificationType(rawValue: value) == PushNotificationType.FriendRequestSent || PushNotificationType(rawValue: value) == PushNotificationType.FriendRequestDeleted {
                    
                //getInvites()
            }
        }
    }
    
    func setupCollectionView() {
        
        collectionView.registerClass(FriendCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fillSuperView(UIEdgeInsetsZero)
        
        collectionView.backgroundColor = .clearColor()
    }
    
    func askForPreferredCurrencyIfNotSet() {
        
        if User.currentUser()?.preferredCurrencyId == nil {
            
            let currency = Currency.CurrencyFromNSNumber(User.currentUser()?.preferredCurrencyId)
            
            UIAlertController.showAlertControllerWithButtonTitle("Change", confirmBtnStyle: .Default, message: "Your preferred currency is \(currency), would you like to change it?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    let v = SelectCurrencyViewController()
                    let nvc = UINavigationController(rootViewController: v)
                    v.delegate = self
                    v.addCloseButton()
                    v.previousValue = User.currentUser()?.preferredCurrencyId
                    self.presentViewController(nvc, animated: true, completion: { () -> Void in
                    })
                }
            })
        }
    }
    
    override func setupView() {
        super.setupView()
        
        view.backgroundColor = colorForViewBackground()
    }
    
    func colorForViewBackground() -> UIColor {

        return kViewBackgroundColor
        //return kDevice == .Phone ? UIColor.whiteColor() : kViewBackgroundColor
    }
    
    func setupToolbar(){
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.sizeToFit()
        view.addSubview(toolbar)
        
        toolbar.addHeightConstraint(relation: .Equal, constant: toolbar.frame.height)
        toolbar.addLeftConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addRightConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        if var height = navigationController?.navigationBar.frame.height {
            
            if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) &&
                !NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 1, patchVersion: 0)){
                
                height += UIApplication.sharedApplication().statusBarFrame.height
                collectionView.contentInset = UIEdgeInsets(top: height, left: collectionView.contentInset.left, bottom: collectionView.contentInset.bottom, right: collectionView.contentInset.right)
            }
        }
        
        let previousInsets = collectionView.contentInset
        collectionView.contentInset = UIEdgeInsets(top: previousInsets.top, left: previousInsets.left, bottom: previousInsets.bottom + toolbar.frame.height, right: previousInsets.right)
        
        toolbar.tintColor = kNavigationBarTintColor
    }
    
//    override func setEditing(editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//        
//        //collectionView.setEditing(editing, animated: animated)
//        
//        if view.bounds.width >= kTableViewMaxWidth {
//            
//            //tableView.reloadData()
//        }
//        
//        if data[2].count > 0 && editing {
//            
//            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2), atScrollPosition: .Top, animated: true)
//        }
//    }
    
    func setBarButtonItems() {
        
        let emptyBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        emptyBarButtonItem.width = 0
        
        addBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add")
        
        
        let invitesText = invitesCount > 0 ? "Invites (\(invitesCount))" : "Invites"
        
        friendInvitesBarButtonItem = UIBarButtonItem(title: invitesText, style: .Plain, target: self, action: "friendInvites")
        openMenuBarButtonItem = UIBarButtonItem(image: kMenuIcon, style: .Plain, target: self, action: "openMenu")
        
        //let editBarButtonItem = editButtonItem() //data[2].count > 0 ? editButtonItem() : UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        
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
        
        addBarButtonItem?.enabled = User.currentUser()?.friends.count > 0
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
        
        //var rc = Array<Array<User>>()
        
        var friendsWhoOweMoney = Array<User>()
        let friendsWhoYouOweMoney = Array<User>()
        let friendsWhoAreEven = Array<User>()
        
        if let currentUser = User.currentUser() {
            
            // TEMP
            
            for friend in currentUser.friends {

                friendsWhoOweMoney.append(friend)
            }
            
            // /TEMP
            
            //owes you money
//            for friend in currentUser.friends {
//                
//                if friend.localeDifferenceBetweenActiveUser.roundToPlaces(2) < 0 {
//                    
//                    friendsWhoOweMoney.append(friend)
//                }
//            }
//            
//            for friend in currentUser.friends {
//                
//                if friend.localeDifferenceBetweenActiveUser.roundToPlaces(2) > 0 {
//                    
//                    friendsWhoYouOweMoney.append(friend)
//                }
//            }
//            
//            for friend in currentUser.friends {
//                
//                if friend.localeDifferenceBetweenActiveUser.roundToPlaces(2) == 0 {
//                    
//                    friendsWhoAreEven.append(friend)
//                }
//            }
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
            
            self.refreshBarButtonItem?.enabled = true
        })
        
        User.currentUser()?.getFriends({ (completedRemoteRequest) -> () in
            
            refreshControl?.endRefreshing()
            self.setDataForTable()
            self.collectionView.reloadData()
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
        view.delegate = self
        
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
            
            self.noDataView.layer.opacity = User.currentUser()?.friends.count > 0 ? 0 : 1
            self.view.backgroundColor = User.currentUser()?.friends.count > 0 ? self.colorForViewBackground() : kViewBackgroundColor
            //self.tableView.separatorColor = User.currentUser()?.friends.count > 0 ? kTableViewSeparatorColor : .clearColor()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        Task.sharedTasker().cancelTaskForIdentifier("GetFriends")
    }
}

extension FriendsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return data.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return data[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! FriendCollectionViewCell
        
        let friend = data[indexPath.section][indexPath.row]
        cell.setup(friend)
        cell.delegate = self
        cell.currentIndexPath = indexPath

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let friend = data[indexPath.section][indexPath.row]
        let v = TransactionsViewController()
        v.friend = friend
        navigationController?.pushViewController(v, animated: true)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let baseHeight:CGFloat = FriendCollectionViewCell.cellPadding() * 1 + FriendCollectionViewCell.friendImageViewWidth()
        var dynamicExtraHeight:CGFloat = 1 * FriendCollectionViewCell.multiCurrencyTableViewCellHeight()
        
        let friend = data[indexPath.section][indexPath.row]
        
        if let data = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[friend.objectId!] {
            
            dynamicExtraHeight = CGFloat(data.keys.count >= 2 ? data.keys.count : 2) * FriendCollectionViewCell.multiCurrencyTableViewCellHeight()
        }
        
        let height = baseHeight + dynamicExtraHeight + (FriendCollectionViewCell.cellPadding() * 2)
        
        var width = (view.frame.width - 60) / 3
        
        if view.frame.width < 700 {
            
            width = view.frame.width - 30
        }
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        
        collectionView.reloadData()
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
            
//            collectionView.beginUpdates()
//            //User.currentUser()?.friends.removeAtIndex(find(User.currentUser()!.friends, friend)!)
//            data[indexPath.section].removeAtIndex(indexPath.row)
//            collectionView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
//            collectionView.endUpdates()
            
            collectionView.deleteItemsAtIndexPaths([indexPath])
        }
        
        NSTimer.schedule(delay: 0.5, handler: { timer in
        
            self.refresh(nil)
        })
    }
}

extension FriendsViewController: MenuDelegate {
    
    func menuDidClose() {
        
        refresh(nil)
    }
}

extension FriendsViewController: SelectCurrencyDelegate {
    
    func didSelectCurrencyId(id: NSNumber) {
        
        Settings.setDefaultCurrencyId(id)
        User.currentUser()?.preferredCurrencyId = id
        User.currentUser()?.saveInBackground()
        collectionView.reloadData()
    }
}