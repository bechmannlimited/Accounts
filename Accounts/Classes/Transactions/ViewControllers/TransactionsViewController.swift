//
//  TransactionsViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 05/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import SwiftyJSON
import Parse
import SVPullToRefresh

private let kPurchaseImage = AppTools.iconAssetNamed("1007-price-tag-toolbar.png")
private let kTransactionImage = AppTools.iconAssetNamed("922-suitcase-toolbar.png")
private let kPopoverContentSize = CGSize(width: 390, height: 440)
private let kLoaderTableFooterViewHeight = 70

private let kBounceViewHeight:CGFloat = 146

protocol SaveItemDelegate {
    
    func itemDidGetDeleted()
    func itemDidChange()
    func purchaseDidChange(purchase: Purchase)
    func transactionDidChange(transaction: Transaction)
    func newItemViewControllerWasPresented(viewController: UIViewController?)
    func dismissPopover()
}

class TransactionsViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Plain)
    var friend = User()
    var transactions:Array<Transaction> = []
    var noDataView = UILabel()
    var addBarButtonItem: UIBarButtonItem?
    
    var refreshBarButtonItem: UIBarButtonItem?
    
    var selectedRow: NSIndexPath?
    
    var selectedPurchaseID: String?
    var selectedTransactionID: String?
    var didJustDelete: Bool = false

    var headerView: BouncyHeaderView?
    
    var bounceViewHeightConstraint: NSLayoutConstraint?
    
    var popoverViewController: UIViewController?
    
    func clean() {
        
        PFObject.unpinAllInBackground(Purchase.query()?.fromLocalDatastore().findObjects() as? [Purchase])
        PFObject.unpinAllInBackground(Transaction.query()?.fromLocalDatastore().findObjects() as? [Transaction])
        //PFObject.unpinAll(Purchase.query()?.fromLocalDatastore().findObjects() as? [Purchase], withName: self.pinLabel())
        //PFObject.unpinAll(Transaction.query()?.fromLocalDatastore().findObjects() as? [Transaction], withName: self.pinLabel())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if kDevice == .Pad {
        
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        setupTableView(tableView, delegate: self, dataSource: self)
        setupNoDataLabel(noDataView, text: "Tap plus to split a bill or add an i.o.u")
        tableView.addSubview(noDataView)
        setupTextLabelForSaveStatusInToolbarWithLabel()
        
        refresh(nil)
        
        setupToolbar()
        addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add")
        refreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refreshFromBarButton")
        
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            refreshBarButtonItem!
        ]
        navigationItem.rightBarButtonItem = addBarButtonItem!
        
        if headerView == nil {
            
            setupBouncyHeaderView()
        }
        
        if kDevice == .Pad {
            
            tableView.contentInset = UIEdgeInsets(top: tableView.contentInset.top + 40, left: tableView.contentInset.left, bottom: tableView.contentInset.bottom, right: tableView.contentInset.right)
        }
        
        view.showLoader()
        self.tableView.separatorColor = UIColor.clearColor()
        self.tableView.layer.opacity = 0.25
        
        if User.currentUser()?.lastSyncedDataInfo == nil { // dont think is needed again...
            
            User.currentUser()?.lastSyncedDataInfo = Dictionary<String, NSDate>()
        }
        
        if let lastSyncedDate = User.currentUser()?.lastSyncedDataInfo?["Transactions_\(self.friend.objectId!)"] {
            
            self.refreshUpdatedDate = lastSyncedDate
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if selectedPurchaseID == nil && selectedTransactionID == nil && !didJustDelete {
            
            findAndScrollToCalculatedSelectedCellAtIndexPath(true)
        }
        
        //getDifferenceAndRefreshIfNeccessary(nil)
        
        tableView.delegate = self // incase it wwasnt set from viewwilldissapear method
        scrollViewDidScroll(tableView)
    }
    
    func setupBouncyHeaderView(){
        
        headerView = BouncyHeaderView()
        headerView?.setupHeaderWithOriginView(view, originTableView: tableView)
        setHeaderTitleText()
        
        if let id = friend.facebookId{
            
            headerView?.getHeroImage("https://graph.facebook.com/\(id)/picture?width=\(500)&height=\(500)")
        }
        else{
            
            //headerView.getHeroImage("http://www.tvchoicemagazine.co.uk/sites/default/files/imagecache/interview_image/intex/michael_emerson.png")
            //headerView.getHeroImage("http://img.joke.co.uk/images/webshop/blog/gangster-silhouette.jpg")
        }
    }
    
    func setHeaderTitleText() {
        
        var text = friend.appropriateDisplayName()
        
        if friend.localeDifferenceBetweenActiveUser > 0 {
            
            text = "\(friend.appropriateDisplayName()) owes \(Formatter.formatCurrencyAsString(abs(friend.localeDifferenceBetweenActiveUser)))"
        }
        else if friend.localeDifferenceBetweenActiveUser < 0 {
            
            text = "You owe \(friend.appropriateDisplayName()) \(Formatter.formatCurrencyAsString(abs(friend.localeDifferenceBetweenActiveUser)))"
        }
        
        headerView?.setupTitle(text)
    }
    
    func getDifferenceBetweenActiveUser() {
    
        PFCloud.callFunctionInBackground("DifferenceBetweenActiveUser", withParameters: ["compareUserId": friend.objectId!]) { (response, error) -> Void in
            
            if let response: AnyObject = response {
                
                let responseJson = JSON(response)
                let difference = responseJson.doubleValue
                
                self.friend.localeDifferenceBetweenActiveUser = difference
                User.currentUser()?.friendsIdsWithDifference?[self.friend.objectId!] = difference
                
                self.setHeaderTitleText()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        popoverViewController = nil // to make sure
        setupInfiniteScrolling()
    }
    
    func refreshFromBarButton(){
        
        refresh(nil)
    }
    
//    override func didReceivePushNotification(notification: NSNotification) {
//        
//        if let object: AnyObject = notification.object{
//            
//            let value = JSON(object[kPushNotificationTypeKey]!!).intValue
//            
//            if PushNotificationType(rawValue: value) == PushNotificationType.ItemSaved{
//                
//                if let userIds = object["userIds"] as? [String] {
//                    
//                    if contains(userIds, friend.objectId!){
//                        
//                        getDifferenceAndRefreshIfNeccessary(nil)
//                    }
//                }
//            }
//        }
//    }
    
    func query() -> PFQuery? {
        
        var query: PFQuery?
        
        let queryForFromUser = Transaction.query()
        queryForFromUser?.whereKey("fromUser", equalTo: User.currentUser()!)
        queryForFromUser?.whereKey("toUser", equalTo: friend)
        
        let queryForToUser = Transaction.query()
        queryForToUser?.whereKey("toUser", equalTo: User.currentUser()!)
        queryForToUser?.whereKey("fromUser", equalTo: friend)
        
        query = PFQuery.orQueryWithSubqueries([queryForFromUser!, queryForToUser!])
        query?.orderByDescending("transactionDate")
        query?.whereKey("objectId", notContainedIn: IOSession.sharedSession().deletedTransactionIds)
        
        activeQueries.append(query)
        
        return query
    }
    
    func transactionIds() -> [String] {
        
        var ids = [String]()
        
        for transaction in transactions {
            
            if let id = transaction.objectId{
                
                ids.append(id)
            }
        }
        
        return ids
    }
    
    func setupToolbar(){
        
        toolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
        toolbar.sizeToFit()
        view.addSubview(toolbar)
        
        toolbar.addHeightConstraint(relation: .Equal, constant: toolbar.frame.height)
        toolbar.addLeftConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addRightConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        var previousInsets = tableView.contentInset
        tableView.contentInset = UIEdgeInsets(top: previousInsets.top, left: previousInsets.left, bottom: previousInsets.bottom + toolbar.frame.height, right: previousInsets.right)
        
        toolbar.tintColor = kNavigationBarTintColor
    }
    
    override func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        setupTableViewRefreshControl(tableView)
        
        setupInfiniteScrolling()
    }
    
    func setupInfiniteScrolling() {
        
        tableView.addInfiniteScrollingWithActionHandler { () -> Void in
            
            var y: CGFloat = self.tableView.contentOffset.y + self.tableView.contentInset.top
            
            if y > 0 {
                
                self.loadMore()
            }
            else{
                
                self.tableView.infiniteScrollingView.stopAnimating()
            }
        }
    }
    
    func showOrHideTableOrNoDataView() {
        
        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
            
            self.noDataView.layer.opacity = self.transactions.count > 0 ? 0 : 1
            self.tableView.layer.opacity = self.transactions.count > 0 ? 1 : 1
            self.tableView.separatorColor = self.transactions.count > 0 ? kTableViewSeparatorColor : .clearColor()
            //self.view.backgroundColor = User.currentUser()!.friends.count > 0 ? .whiteColor() : UIColor.groupTableViewBackgroundColor()
        })
    }
    
//    func pinLabel() -> String {
//        
//        return "\(User.currentUser()!.objectId!)_\(self.friend.objectId!)"
//    }
    
//    func executeActualRefreshByHiding(hiding: Bool, refreshControl: UIRefreshControl?, take:Int?, completion: ( ()-> ())?) {
//        
//        refreshBarButtonItem?.enabled = false
//        
//        if hiding {
//            
//            noDataView.layer.opacity = 0 // need to re-check this bit
//        }
//        
//        cancelQueries()
//        
//        getDifferenceBetweenActiveUser()
//        
//        let remoteQuery = query()
//        
//        remoteQuery?.skip = 0
//        remoteQuery?.limit = 16
//        //remoteQuery?.cachePolicy = PFCachePolicy.CacheThenNetwork
//        var queriesExecuted = 0
//        
//        //var purchaseDictionary = Dictionary<String, Purchase?>()
//        
//        if transactions.count > 16 && transactions.count < 35 {
//            
//            remoteQuery?.limit = transactions.count
//        }
//        
//        //var objectsReturnedFromLocalQuery = [PFObject]()
//        
//        let executeRemoteQuery: () -> () = {
//            
//            self.refreshBarButtonItem?.enabled = false
//            
//            remoteQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
//
//                if var transactions = objects as? [Transaction] {
//                    
//                    Task.executeTaskInBackground({ () -> () in
//                        
//                        if error == nil {
//                            
//                            PFObject.unpinAll(self.query()?.fromLocalDatastore().findObjects())
//                            
//                            var unpinPurchasesQuery1 = Purchase.query()?.whereKey("user", equalTo: User.currentUser()!)
//                            var unpinPurchasesQuery2 = Purchase.query()?.whereKey("user", equalTo: self.friend)
//                            var unpinPurchasesQuery = PFQuery.orQueryWithSubqueries([unpinPurchasesQuery1!, unpinPurchasesQuery2!]).fromLocalDatastore()
//                            // may need to removed from 
//                            
//                            PFObject.unpinAll(unpinPurchasesQuery.findObjects(), withName: self.pinLabel())
//                            PFObject.pinAllInBackground(transactions, withName: self.pinLabel())
//                            
////                            PFObject.unpinAll(unpinPurchasesQuery.findObjects())
////                            PFObject.pinAllInBackground(transactions)
//                            
////                            for transaction in transactions {
////                                
////                                if let id = transaction.purchaseObjectId {
////                                    
////                                    transaction.purchase = Purchase.query()?.getObjectWithId(id) as? Purchase
////                                    transaction.purchase?.pinInBackgroundWithName(self.pinLabel())
////                                    purchaseDictionary[transaction.objectId!] = transaction.purchase
////                                }
////                            }
//                            
//                            self.transactions = transactions
//                        }
//                        else{
//                            
//                            self.refreshBarButtonItem?.enabled = true // needed (this is twice)
//                        }
//
//                    }, completion: { () -> () in
//                        
//                        queriesExecuted++
//                        
//                        refreshControl?.endRefreshing()
//                        self.tableView.reloadData()
//                        self.view.hideLoader()
//                        self.showOrHideTableOrNoDataView()
//                        
//                        //if queriesExecuted == 2 {
//                            
//                            self.findAndScrollToCalculatedSelectedCellAtIndexPath(true)
//                        //}
//
//                        self.refreshBarButtonItem?.enabled = true
//                        
//                        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
//                            
//                            self.tableView.layer.opacity = 1
//                        })
//                        
//                        completion?()
//                    })
//                }
//                else{
//                    
//                    self.refreshBarButtonItem?.enabled = true
//                }
//            })
//        }
//
//        let localQuery: PFQuery? = query()
//        localQuery?.fromPinWithName(self.pinLabel())
//        //localQuery?.fromLocalDatastore()
//        localQuery?.limit = 35
//        
//        localQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
//            
//            var successful = true
//            
//            Task.executeTaskInBackground({ () -> () in
//                
//                var transactionsNotAvailable = [Transaction]()
//                
//                if var transactions = objects as? [Transaction] {
//
//                    for transaction in transactionsNotAvailable {
//                        
//                        let index = find(transactions, transaction)!
//                        transactions.removeAtIndex(index)
//                    }
//                    self.transactions = transactions
//                }
//                
//            }, completion: { () -> () in
//                
//                if successful {
//                    
//                    refreshControl?.endRefreshing()
//                    self.tableView.reloadData()
//                    self.view.hideLoader()
//                    self.showOrHideTableOrNoDataView()
//                    //self.findAndScrollToCalculatedSelectedCellAtIndexPath(false)
//                    
//                    completion?()
//                }
//                
//                self.refreshBarButtonItem?.enabled = true
//
//                executeRemoteQuery()
//            })
//        })
//    }
    
    func findAndScrollToCalculatedSelectedCellAtIndexPath(shouldDeselect: Bool) {
        
        if !didJustDelete {
            
            var calculatedIndexPath: NSIndexPath?
            
            for transaction in transactions {
                
                let row = find(transactions, transaction)!
                
                if let purchaseID = selectedPurchaseID {
                    
                    if transaction.purchaseObjectId == purchaseID {
                        
                        calculatedIndexPath = NSIndexPath(forRow: row, inSection: 0)
                        break
                    }
                }
                if let transactionID = selectedTransactionID {
                    
                    if transaction.objectId == transactionID {
                        
                        calculatedIndexPath = NSIndexPath(forRow: row, inSection: 0)
                        break
                    }
                }
            }
            
            var rowToDeselect: NSIndexPath?
            
            if let indexPath = calculatedIndexPath {
                
                rowToDeselect = indexPath
            }
            else if let indexPath = selectedRow {
                
                rowToDeselect = indexPath
            }
            else if selectedPurchaseID == nil && selectedTransactionID == nil {
                
                rowToDeselect = nil // for now (needsto get id from postback) / /is this still true?
                
                if transactions.count > 0 {
                    
                    tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Middle, animated: false)
                }
            }
            if let indexPath = rowToDeselect {
                
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                
                if shouldDeselect {
                    
                    NSTimer.schedule(delay: kAnimationDuration, handler: { timer in
                        
                        var cellRect = self.tableView.rectForRowAtIndexPath(indexPath)
                        
                        let rectToCheck = CGRect(x: self.tableView.bounds.origin.x, y: self.tableView.bounds.origin.y + 64, width: self.tableView.bounds.width, height: self.tableView.bounds.height - 64 - 44)
                        
                        var completelyVisible = CGRectContainsRect(rectToCheck, cellRect)
                        
                        if !completelyVisible {
                            
                            CATransaction.begin()
                            CATransaction.setCompletionBlock({ () -> Void in
                                
                                self.deselectSelectedCell(self.tableView)
                            })
                            
                            self.tableView.beginUpdates()
                            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                            self.tableView.endUpdates()
                            
                            CATransaction.commit()
                        }
                        else {
                            
                            self.deselectSelectedCell(self.tableView)
                        }
                    })
                }
            }
        }
        
        if shouldDeselect {
            
            selectedTransactionID = nil
            selectedPurchaseID = nil
            selectedRow = nil
            didJustDelete = false
        }
    }
    
    override func refresh(refreshControl: UIRefreshControl?) {
        
        selectedTransactionID = nil
        selectedPurchaseID = nil
        selectedRow = nil
        didJustDelete = false
        
        cancelQueries()
        
        getDifferenceBetweenActiveUser()
        
        reloadTableViewFromLocalDataSource { () -> () in
            
            self.refreshBarButtonItem?.enabled = false
            
            NSTimer.schedule(delay: 10, handler: { timer in
                
                refreshBarButtonItem?.enabled = true
            })
            
            var remoteQuery = self.query()
            remoteQuery?.limit = 16
            
            remoteQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if let transactions = objects as? [Transaction] {
                    
                    Task.executeTaskInBackground({ () -> () in
                        
                        PFObject.unpinAll(self.query()?.fromLocalDatastore().findObjects())
                        PFObject.pinAll(transactions)
                        
                        self.transactions = transactions
                        
                    }, completion: { () -> () in
                        
                        refreshControl?.endRefreshing()
                        self.tableView.reloadData()
                        self.view.hideLoader()
                        self.showOrHideTableOrNoDataView()
                        self.findAndScrollToCalculatedSelectedCellAtIndexPath(true)
                        self.refreshBarButtonItem?.enabled = true
                        
                        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
                            
                            self.tableView.layer.opacity = 1
                        })
                        
                        //last synced label
                        User.currentUser()?.lastSyncedDataInfo?["Transactions_\(self.friend.objectId!)"] = NSDate()
                        self.refreshUpdatedDate = NSDate()
                    })
                }
            })
        }
    }
    
    func reloadTableViewFromLocalDataSource(completion: (() -> ())?) {
        
        self.refreshBarButtonItem?.enabled = false
        
        var localQuery = query()?.fromLocalDatastore()
        localQuery?.limit = 35
        
        localQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
            
            var transactionsNotAvailable = [Transaction]()
            
            if var transactions = objects as? [Transaction] {
                
                for transaction in transactionsNotAvailable {
                    
                    let index = find(transactions, transaction)!
                    transactions.removeAtIndex(index)
                }
                
                self.transactions = transactions
                
                self.tableView.reloadData()
                self.view.hideLoader()
                self.showOrHideTableOrNoDataView()
                //self.findAndScrollToCalculatedSelectedCellAtIndexPath(true)
                self.refreshBarButtonItem?.enabled = true
                
                UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
                    
                    self.tableView.layer.opacity = 1
                })
            }
            
            completion?()
        })
    }
    
//    func fetchTransactionsFromCloud(){
//        
//        
//    }
    
    func cancelQueries(){
        
        for query in activeQueries {
            
            query?.cancel()
        }
    }
    
    func loadMore() {
        
        cancelQueries()
        let skip = 16
        
        if transactions.count >= skip {
            
            let loadMoreQuery = query()
            
            //loadMoreQuery?.skip = transactions.count
            loadMoreQuery?.limit = skip
            loadMoreQuery?.whereKey("objectId", notContainedIn: transactionIds())
            
            loadMoreQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if let transactions = objects as? [Transaction] {
                    
                    for transaction in transactions {
                        
                        self.transactions.append(transaction)
                        transaction.pinInBackground()
                    }
                }
                
                self.tableView.infiniteScrollingView.stopAnimating()
                self.tableView.reloadData()
                self.showOrHideTableOrNoDataView() // just in case
            })
        }
        else{
            
            self.tableView.infiniteScrollingView.stopAnimating()
        }
    }
    
    func add() {
        
        let view = SelectPurchaseOrTransactionViewController()
        view.contextualFriend = friend
        view.saveItemDelegate = self
        let v = UINavigationController(rootViewController: view)
        
        v.modalPresentationStyle = .Popover
        v.preferredContentSize = kPopoverContentSize
        v.popoverPresentationController?.barButtonItem = addBarButtonItem
        v.popoverPresentationController?.delegate = self
        
        popoverViewController = view // needed? added this not sure why its here lol
        
        presentViewController(v, animated: true, completion: nil)
    }
    
    override func setupTableViewConstraints(tableView: UITableView) {
        
        //setupBounceView()
        
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        tableView.addLeftConstraint(toView: view, attribute: NSLayoutAttribute.Left, relation: NSLayoutRelation.GreaterThanOrEqual, constant: -0)
        tableView.addRightConstraint(toView: view, attribute: NSLayoutAttribute.Right, relation: NSLayoutRelation.GreaterThanOrEqual, constant: -0)
        
        tableView.addWidthConstraint(relation: NSLayoutRelation.LessThanOrEqual, constant: kTableViewMaxWidth)
        
        tableView.addTopConstraint(toView: view, relation: .Equal, constant: 0)
        tableView.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        tableView.addCenterXConstraint(toView: view)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        
        tableView.delegate = nil
    }
}

extension TransactionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return transactions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: identifier)
        })
        
        let transaction = transactions[indexPath.row]
        
        var amount = transaction.localeAmount
        
//        if let purchaseObjectId = transaction.purchaseObjectId {
//
//            if let purchase = transaction.purchase {
//                
//                amount = purchase.amount
//            }
//            
//            //let dateString:String = transaction.purchase.purchasedDate!.toString(DateFormat.Date.rawValue)
//            cell.textLabel?.text = "\(transaction.title!)"
//            cell.imageView?.image = kPurchaseImage
//        }
 
        
        
        let dateString:String = transaction.transactionDate.toString(DateFormat.Date.rawValue)
        cell.imageView?.image = kTransactionImage
        
        let tintColor = transaction.toUser?.objectId == User.currentUser()?.objectId ? AccountColor.negativeColor() : AccountColor.positiveColor()
        
        cell.detailTextLabel?.textColor = tintColor
        cell.imageView?.tintWithColor(tintColor)
        
        let amountText = Formatter.formatCurrencyAsString(abs(amount))
        let iouText = transaction.fromUser == User.currentUser() ? "\(transaction.toUser!.firstName) owes you \(amountText)" : "You owe \(amountText)"
        
        cell.textLabel?.text = "\(transaction.title!)"
        cell.detailTextLabel?.text = iouText
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        //cell.imageView?.tintWithColor(AccountColor.blueColor())
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let transaction = transactions[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        
        if transaction.purchaseObjectId != nil {
            
            let v = SavePurchaseViewController()
            
            v.purchaseObjectId = transaction.purchaseObjectId! //transaction.purchase
            v.delegate = self
            openView(v, sourceView: cell.contentView)
        }
        else {
            
            let v = SaveTransactionViewController()
            
            v.transaction = transaction.copyWithUsefulValues()
            v.transactionObjectId = transaction.objectId
            v.existingTransaction = transaction
            v.isExistingTransaction = true
            
            v.delegate = self
            openView(v, sourceView: cell.contentView)
        }
        
        selectedRow = indexPath
    }
    
    func openView(view: UIViewController, sourceView: UIView?) {
        
        let v = UINavigationController(rootViewController: view)
        
        v.modalPresentationStyle = .Popover
        v.preferredContentSize = kPopoverContentSize
        v.popoverPresentationController?.sourceRect = sourceView!.bounds
        v.popoverPresentationController?.sourceView = sourceView
        v.popoverPresentationController?.delegate = self
        v.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Left
        
        popoverViewController = view
        
        presentViewController(v, animated: true, completion: nil)
    }
    
//    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        
//        if friend.localeDifferenceBetweenActiveUser > 0 {
//            
//            return "\(friend.appropriateDisplayName()) owes you: \(Formatter.formatCurrencyAsString(abs(friend.localeDifferenceBetweenActiveUser)))"
//        }
//        else if friend.localeDifferenceBetweenActiveUser < 0 {
//            
//            return "You owe \(friend.appropriateDisplayName()): \(Formatter.formatCurrencyAsString(abs(friend.localeDifferenceBetweenActiveUser)))"
//        }
//        
//        return ""
//    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0 // CGFloat.min + (kDevice == .Pad ? 40 : 0)
    }
    
    override func setupTableViewRefreshControl(tableView: UITableView) {
        
        
    }
}

extension TransactionsViewController: UIPopoverPresentationControllerDelegate {
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        
        popoverViewController = nil
        deselectSelectedCell(tableView)
        scrollViewDidScroll(tableView)
        //getDifferenceAndRefreshIfNeccessary(nil)
    }
    
    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        
        if let viewController = popoverViewController as? SavePurchaseViewController {
            
            viewController.askToPopIfChanged() // was popall
            return false
        }
        else if let viewController = popoverViewController as? SaveTransactionViewController {
            
            viewController.askToPopIfChanged() // was popall
            return false
        }
        else {
            
            return true
        }
    }
    
//    func popoverPresentationController(popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverToRect rect: UnsafeMutablePointer<CGRect>, inView view: AutoreleasingUnsafeMutablePointer<UIView?>) {
//        
//        popoverPresentationController.backgroundColor = UIColor.clearColor()
//    }
}

extension TransactionsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        var y: CGFloat = scrollView.contentOffset.y + scrollView.contentInset.top

        if y < 86 {

            navigationController?.navigationBar.tintColor = UIColor.whiteColor()
            navigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(.clearColor(), size: CGSize(width: 10, height: 10)), forBarMetrics: .Default)
            navigationController?.navigationBar.shadowImage = UIImage.imageWithColor(.clearColor(), size: CGSize(width: 1, height: 1))
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        }
        else{

            setNavigationControllerToDefault()
        }
        
        headerView?.scrollViewDidScroll(scrollView)
    }
}

extension TransactionsViewController: SaveItemDelegate {
    
    func itemDidGetDeleted() {
        
        didJustDelete = true
        itemDidChange()
    }
    
    func itemDidChange() {
        
        refresh(nil)
    }
    
    func transactionDidChange(transaction: Transaction) {
        
        selectedPurchaseID = nil
        selectedTransactionID = transaction.objectId
        selectedRow = nil
    }
    
    func purchaseDidChange(purchase: Purchase) {
        
        selectedTransactionID = nil
        selectedPurchaseID = purchase.objectId
        selectedRow = nil
    }
    
    func newItemViewControllerWasPresented(viewController: UIViewController?) {
    
        popoverViewController = viewController
    }
    
    func dismissPopover() {
        
        
    }
}

