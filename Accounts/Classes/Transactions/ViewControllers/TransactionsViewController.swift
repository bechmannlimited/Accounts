//
//  TransactionsViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 05/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
 
import SwiftyJSON
import Parse
import SVPullToRefresh
import SwiftOverlays

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
    var addBarButtonItem: UIBarButtonItem?
    
    var refreshBarButtonItem: UIBarButtonItem?
    
    var selectedRow: NSIndexPath?
    
    var selectedPurchaseID: String?
    var selectedTransactionID: String?
    var didJustDelete: Bool = false

    var headerView: BouncyHeaderView?
    var headerViewScreenShotImage: UIImage?
    
    var bounceViewHeightConstraint: NSLayoutConstraint?
    
    var popoverViewController: UIViewController?
    private var blurViewHasBeenConverted = false
    
    let multiCurrencyTableView = MultiCurrencyTableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if kDevice == .Pad {
        
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        setupTableView(tableView, delegate: self, dataSource: self)
        
        let noDataMessage: String = friend.objectId == kTestBotObjectId ? "ioubot will allow you to test out some of the features of this app before you invite your friends. Tap plus to have a go!" : "Tap plus to split a bill, add an i.o.u or a payment"
        
        setupNoDataLabel(noDataView, text: noDataMessage, originView: tableView)
        tableView.addSubview(noDataView)
        setupTextLabelForSaveStatusInToolbarWithLabel()
        
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
        
        self.tableView.layer.opacity = 0.25
        
        if User.currentUser()?.lastSyncedDataInfo == nil { // dont think is needed again...
            
            User.currentUser()?.lastSyncedDataInfo = Dictionary<String, NSDate>()
        }
        
        if let lastSyncedDate = User.currentUser()?.lastSyncedDataInfo?["Transactions_\(self.friend.objectId!)"] {
            
            self.refreshUpdatedDate = lastSyncedDate
        }
        
        refresh(nil)
        
        tableView.contentInset = UIEdgeInsets(top: tableView.contentInset.top - 64, left: tableView.contentInset.left, bottom: tableView.contentInset.bottom, right: tableView.contentInset.right)
    }
    
    func setTableViewHeaderFromLocalData() {
        
        if let user = User.currentUser() {
            
            if let results = user.friendsIdsWithDifferenceWithMultipleCurrencies?[friend.objectId!] {
                
                if self.transactions.count > 0 {
                    
                    self.multiCurrencyTableView.results = results
                    self.multiCurrencyTableView.friend = self.friend
                    self.multiCurrencyTableView.delegate = self.multiCurrencyTableView
                    self.multiCurrencyTableView.dataSource = self.multiCurrencyTableView
                    let extraHeight:CGFloat = kDevice == .Pad ? 20 : 0
                    self.multiCurrencyTableView.frame = CGRect(x: 0, y: 0, width: 100, height: self.multiCurrencyTableView.calculatedHeight() + extraHeight)
                    self.multiCurrencyTableView.separatorColor = .clearColor()
                    self.multiCurrencyTableView.reloadData()
                    self.tableView.tableHeaderView = self.multiCurrencyTableView
                }
                else {
                    
                    self.tableView.tableHeaderView = nil
                }
            }
        }
    }
    
    func setupTableViewHeader() {
        
        setTableViewHeaderFromLocalData()
        
        //TODO: cache changes to friend object + currenct user
        PFCloud.callFunctionInBackground("DifferenceBetweenActiveUserWithMultipleCurrencies", withParameters: ["compareUserId": friend.objectId!]) { (r, error) -> Void in
            
            if let r = r {
                
                let result:JSON = JSON(r)
                var results = Dictionary<CurrencyEnum, NSNumber>()
                var stringResults = Dictionary<String, NSNumber>()
                
                for (currencyId, amountJson):(String, JSON) in result {
                    
                    let currencyNSNumber = NSNumber(float: NSNumberFormatter().numberFromString(currencyId)!.floatValue)
                    let currency = Currency.CurrencyFromNSNumber(currencyNSNumber)
                    let amount = amountJson.numberValue
                    
                    if amount != 0 {
                        
                        results[currency] = amount
                        stringResults["\(currencyNSNumber)"] = amount
                    }
                }
                
                self.friend.differencesBetweenActiveUser = stringResults
                User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[self.friend.objectId!] = stringResults
                
                self.setTableViewHeaderFromLocalData()
            }
            else {
                
                //ParseUtilities.showAlertWithErrorIfExists(error)
            }
        }
    }
    
    func setupBackgroundBlurView() {
        
        if kDevice == .Phone {
            
            if friend.objectId == kTestBotObjectId || friend.facebookId != nil {
                
                let imageView = UIImageView(frame: view.bounds)
                imageView.layer.opacity = 0
                view.addSubview(imageView)
                view.sendSubviewToBack(imageView)
                
                if friend.objectId == kTestBotObjectId {
                    
                    imageView.image = AppTools.iconAssetNamed("50981152_thumbnail.jpg")
                    
                    UIView.animateWithDuration(kHeroImageAnimationDuration, animations: { () -> Void in
                        
                        imageView.layer.opacity = 1
                        
                    }, completion: { (finished) -> Void in
                    })
                }
                else if let id = friend.facebookId{
                    
                    let url = "https://graph.facebook.com/\(id)/picture?width=\(500)&height=\(500)"
                    
                    ABImageLoader.sharedLoader().loadImageFromCacheThenNetwork(url, completion: { (image) -> () in
                        
                        imageView.image = image
                        
                        UIView.animateWithDuration(kHeroImageAnimationDuration, animations: { () -> Void in
                            
                            imageView.layer.opacity = 1
                            
                        }, completion: { (finished) -> Void in
                        })
                    })
                }
                
                let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
                blurView.frame = imageView.bounds
                imageView.addSubview(blurView)
                
                let cover = UIView()
                cover.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(kDevice == .Pad ? 0.75 : 0.45)
                cover.frame = imageView.bounds
                imageView.addSubview(cover)
            }
        }
    }
    
    var viewHasAppeared = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if selectedPurchaseID == nil && selectedTransactionID == nil && !didJustDelete {
            
            findAndScrollToCalculatedSelectedCellAtIndexPath(true)
        }
        
        setHeaderTitleText()
        tableView.delegate = self // incase it wasnt set due to viewwilldissapear method
        scrollViewDidScroll(tableView)
        
        if !viewHasAppeared {
            
            headerView?.bounceHeaderFromPushTransition()
        }
        
        viewHasAppeared = true
        
        if tableView.infiniteScrollingView != nil {
            
            tableView.infiniteScrollingView.stopAnimating()
        }
    }
    
    override func setupView() {
        super.setupView()
        
        view.backgroundColor = colorForViewBackground()
    }
    
    func colorForViewBackground() -> UIColor {
        
        return kDevice == .Phone ? UIColor.whiteColor() : kViewBackgroundColor
    }
    
    func setupBouncyHeaderView(){
        
        headerView = BouncyHeaderView()
        headerView?.setupHeaderWithOriginView(view, originTableView: tableView)
        setHeaderTitleText()
        
        if friend.objectId == kTestBotObjectId {
            
            headerView?.heroImageView.image = AppTools.iconAssetNamed("50981152_thumbnail.jpg")
        }
        else if let id = friend.facebookId{
            
            headerView?.getHeroImage("https://graph.facebook.com/\(id)/picture?width=\(500)&height=\(500)")
        }
        else{
            
        }
    }
    
    func setHeaderTitleText() {
        
        let text = friend.appropriateDisplayName()
        headerView?.setupTitle(text)
        
        //setupTableViewHeader()
    }
    
    func getDifferenceBetweenActiveUser() {
    
        setupTableViewHeader()
        
        //TODO: Get diff between active user
//        PFCloud.callFunctionInBackground("DifferenceBetweenActiveUser", withParameters: ["compareUserId": friend.objectId!]) { (response, error) -> Void in
//            
//            if let response: AnyObject = response {
//                
//                let responseJson = JSON(response)
//                let difference = responseJson.doubleValue
//                
//                self.friend.localeDifferenceBetweenActiveUser = difference
//                User.currentUser()?.friendsIdsWithDifference?[self.friend.objectId!] = difference
//                
//                self.setHeaderTitleText()
//            }
//        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !blurViewHasBeenConverted {
            
            setupBackgroundBlurView()
        }
        
        popoverViewController = nil // to make sure
        setupInfiniteScrolling()
    }
    
    func refreshFromBarButton(){
        
        refresh(nil)
    }
    
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
        query?.whereKey("isDeleted", notEqualTo: true)
        
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
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.sizeToFit()
        view.addSubview(toolbar)
        
        toolbar.addHeightConstraint(relation: .Equal, constant: toolbar.frame.height)
        toolbar.addLeftConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addRightConstraint(toView: view, relation: .Equal, constant: 0)
        toolbar.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        let previousInsets = tableView.contentInset
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
            
            let y: CGFloat = self.tableView.contentOffset.y + self.tableView.contentInset.top
            
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
            self.tableView.separatorColor = self.transactions.count > 0 ? kTableViewSeparatorColor : .clearColor()
            self.view.backgroundColor = self.transactions.count > 0 ? self.colorForViewBackground() : kViewBackgroundColor
        })
    }
    
    override func setNavigationControllerToDefault(){
        
        navigationController?.navigationBar.tintColor = .whiteColor()
        navigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(.clearColor(), size: CGSize(width: 10, height: 10)), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = UIImage.imageWithColor(.clearColor(), size: CGSize(width: 10, height: 10))
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    func findAndScrollToCalculatedSelectedCellAtIndexPath(shouldDeselect: Bool) {
        
        if !didJustDelete {
            
            var calculatedIndexPath: NSIndexPath?
            
            for transaction in transactions {
                
                let row = transactions.indexOf(transaction)!
                
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
                    
                    //tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
                }
            }
            if let indexPath = rowToDeselect {
                print(indexPath)
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                
                if shouldDeselect {
                    
                    NSTimer.schedule(delay: kAnimationDuration, handler: { timer in
                        
                        let cellRect = self.tableView.rectForRowAtIndexPath(indexPath)
                        
                        let rectToCheck = CGRect(x: self.tableView.bounds.origin.x, y: self.tableView.bounds.origin.y + 64, width: self.tableView.bounds.width, height: self.tableView.bounds.height - 64 - 44)
                        
                        let completelyVisible = CGRectContainsRect(rectToCheck, cellRect)
                        
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
        // ^ remove both these when findandscrolltoselected row is working
        
        selectedRow = nil
        didJustDelete = false
        
        cancelQueries()
        
        getDifferenceBetweenActiveUser()
        
        reloadTableViewFromLocalDataSource { () -> () in
            
            self.refreshBarButtonItem?.enabled = false
            
            NSTimer.schedule(delay: 10, handler: { timer in
                
                self.refreshBarButtonItem?.enabled = true
            })
            
            let remoteQuery = self.query()
            remoteQuery?.limit = 16
            
            remoteQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if let transactions = objects as? [Transaction] {
                    
                    Task.sharedTasker().executeTaskInBackground({ () -> Void in
                        
                        do {
                            try PFObject.unpinAll(self.query()?.fromLocalDatastore().findObjects())
                            try PFObject.pinAll(transactions)
                        }
                        catch { }
                        
                    }, completion: { () -> () in
                        
                        self.reloadTableViewFromLocalDataSource(nil)
                        
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
        
        let localQuery = query()?.fromLocalDatastore()
        
        localQuery?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
            
            let transactionsNotAvailable = [Transaction]()
            
            if var transactions = objects as? [Transaction] {
                
                for transaction in transactionsNotAvailable {
                    
                    let index = transactions.indexOf(transaction)!
                    transactions.removeAtIndex(index)
                }
                
                self.transactions = transactions
                self.reorderTransactions()
                self.tableView.reloadData()
                self.view.hideLoader()
                self.showOrHideTableOrNoDataView()
                //self.setupTableViewHeader()
                self.setTableViewHeaderFromLocalData()
                self.refreshBarButtonItem?.enabled = true
                //self.findAndScrollToCalculatedSelectedCellAtIndexPath(true)
                
                UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
                    
                    self.tableView.layer.opacity = 1
                })
            }
            
            completion?()
        })
    }
    
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
                    
                    Task.sharedTasker().executeTaskInBackground({ () -> Void in
                        
                        do { try PFObject.pinAll(transactions) } catch {}
                        
                    }, completion: { () -> () in
                        
                        self.reloadTableViewFromLocalDataSource({ () -> () in
                            
                            self.tableView.infiniteScrollingView.stopAnimating()
                        })
                    })
                }
                else {
                    
                    self.tableView.infiniteScrollingView.stopAnimating()
                }
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
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.addLeftConstraint(toView: view, attribute: NSLayoutAttribute.Left, relation: NSLayoutRelation.GreaterThanOrEqual, constant: -0)
        tableView.addRightConstraint(toView: view, attribute: NSLayoutAttribute.Right, relation: NSLayoutRelation.GreaterThanOrEqual, constant: -0)
        
        tableView.addWidthConstraint(relation: NSLayoutRelation.LessThanOrEqual, constant: kTableViewMaxWidth)
        
        tableView.addTopConstraint(toView: view, relation: .Equal, constant: navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height)
        tableView.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        tableView.addCenterXConstraint(toView: view)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        tableView.delegate = nil
    }
}

extension TransactionsViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return transactions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: TransactionTableViewCell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return TransactionTableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: identifier)
        }) as! TransactionTableViewCell
        
        let transaction = transactions[indexPath.row]
        
        cell.setupCell(transaction)

        cell.backgroundColor = kDevice == .Pad ? UIColor.whiteColor() : UIColor.whiteColor().colorWithAlphaComponent(0.5)
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        cell.layer.shouldRasterize = true
        
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
            v.isInsidePopover = kDevice == .Pad
            v.delegate = self
            
            if #available(iOS 9.0, *) {
                
                if transaction.isSecure && NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) && NKTouchID.canUseTouchID() {
                    
                    NKTouchID.authenticateWithTouchId(reason: "Please verify yourself to open this transaction!", callback: { (success, error) in
                        
                        if success {
                            
                            self.openView(v, sourceView: cell.contentView)
                        }
                        else {
                            print(error)
                            self.deselectSelectedCell(tableView)
                        }
                    })
                }
                else {
                    
                    openView(v, sourceView: cell.contentView)
                }
            }
            else {
            
                openView(v, sourceView: cell.contentView)
            }
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
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0 // CGFloat.min + (kDevice == .Pad ? 40 : 0)
    }
    
    override func setupTableViewRefreshControl(tableView: UITableView) {
        
        
    }
    
    func reorderTransactions() {
        
        transactions.sortInPlace { return $0.transactionDate.timeIntervalSince1970 > $1.transactionDate.timeIntervalSince1970 }
    }
}

extension TransactionsViewController: UIPopoverPresentationControllerDelegate {
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        
        popoverViewController = nil
        deselectSelectedCell(tableView)
        scrollViewDidScroll(tableView)
        setNavigationControllerToDefault()
        setHeaderTitleText()
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
}

extension TransactionsViewController {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
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
