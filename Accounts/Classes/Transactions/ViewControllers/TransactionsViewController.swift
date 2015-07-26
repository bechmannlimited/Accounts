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

private let kPurchaseImage = AppTools.iconAssetNamed("1007-price-tag-toolbar.png")
private let kTransactionImage = AppTools.iconAssetNamed("922-suitcase-toolbar.png")
private let kPopoverContentSize = CGSize(width: 390, height: 440)
private let kLoaderTableFooterViewHeight = 70
private let kAnimationDuration:NSTimeInterval = 0.5

protocol SaveItemDelegate {
    
    func itemDidGetDeleted()
    func itemDidChange()
    func purchaseDidChange(purchase: Purchase)
    func transactionDidChange(transaction: Transaction)
    func newItemViewControllerWasPresented(viewController: UIViewController?)
    func dismissPopover()
}

class TransactionsViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
    var friend = User()
    var transactions:Array<Transaction> = []
    var noDataView = UILabel()
    var addBarButtonItem: UIBarButtonItem?
    
    var loadMoreView = UIView()
    var loadMoreViewHeightConstraint: NSLayoutConstraint?
    var hasLoadedFirstTime = false

    var isLoadingMore = false
    var canLoadMore = true
    
    var selectedRow: NSIndexPath?
    
    var selectedPurchaseID: String?
    var selectedTransactionID: String?
    var didJustDelete: Bool = false
    
    //var refreshQuery: PFQuery?
    //var loadMoreQuery: PFQuery?
    var query: PFQuery?
    
    var popoverViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupQuery()
        
        if kDevice == .Pad {
        
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        setupTableView(tableView, delegate: self, dataSource: self)
        title = "Transactions with \(friend.appropriateDisplayName())"
        
        addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add")
        navigationItem.rightBarButtonItem = addBarButtonItem

        setupLoadMoreView()
        setupNoDataLabel(noDataView, text: "Tap plus to add a purchase or transfer")
        
        executeActualRefreshByHiding(true, refreshControl: nil, take: nil, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if selectedPurchaseID == nil && selectedTransactionID == nil && !didJustDelete {
            
            findAndScrollToCalculatedSelectedCellAtIndexPath()
        }
        
        getDifferenceAndRefreshIfNeccessary(nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        popoverViewController = nil // to make sure
    }
    
    override func didReceivePushNotification(notification: NSNotification) {
        
        if let object: AnyObject = notification.object{
            
            let value = JSON(object[kPushNotificationTypeKey]!!).intValue
            
            if PushNotificationType(rawValue: value) == PushNotificationType.ItemSaved{
                
                if let userIds = object["userIds"] as? [String] {
                    
                    if contains(userIds, friend.objectId!){
                        
                        getDifferenceAndRefreshIfNeccessary(nil)
                    }
                }
            }
        }
    }
    
    func setupQuery() {
        
        let queryForFromUser = Transaction.query()
        queryForFromUser?.whereKey("fromUser", equalTo: User.currentUser()!)
        queryForFromUser?.whereKey("toUser", equalTo: friend)
        
        let queryForToUser = Transaction.query()
        queryForToUser?.whereKey("toUser", equalTo: User.currentUser()!)
        queryForToUser?.whereKey("fromUser", equalTo: friend)
        
        query = PFQuery.orQueryWithSubqueries([queryForFromUser!, queryForToUser!])
        query?.includeKey("purchase")
        query?.orderByDescending("transactionDate")
    }
    
    func getDifferenceAndRefreshIfNeccessary(refreshControl: UIRefreshControl?) {
        
        PFCloud.callFunctionInBackground("DifferenceBetweenActiveUser", withParameters: ["compareUserId": friend.objectId!]) { (response, error) -> Void in
            
            let responseJson = JSON(response!)
            let difference = responseJson.doubleValue
            
            let previousDifference = self.friend.localeDifferenceBetweenActiveUser
            self.friend.localeDifferenceBetweenActiveUser = difference
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()

            if previousDifference != difference {

                println("found difference (transactionscontroller)")
                self.executeActualRefreshByHiding(true, refreshControl: nil, take: nil, completion: nil)
            }
            else {
                
                println("found no difference")
                refreshControl?.endRefreshing()
            }
        }
    }
    
    override func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        setupTableViewRefreshControl(tableView)
    }
    
    func showOrHideTableOrNoDataView() {
        
        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
            
            self.noDataView.layer.opacity = self.transactions.count > 0 ? 0 : 1
            self.tableView.layer.opacity = self.transactions.count > 0 ? 1 : 1
        })
    }
    
    func executeActualRefreshByHiding(hiding: Bool, refreshControl: UIRefreshControl?, take:Int?, completion: ( ()-> ())?) {
        
        if hiding {
            
            view.showLoader()
            tableView.layer.opacity = 0
            noDataView.layer.opacity = 0
        }
    
        query?.cancel()
        query?.skip = 0
        query?.limit = 16
        
        Task.executeTaskInBackground({ () -> () in
            
            if var transactions = self.query?.findObjects() as? [Transaction] {
                
                for transaction in transactions {
                    
                    if transaction.fromUser?.objectId == transaction.toUser?.objectId {
                        
                        let index = find(transactions, transaction)!
                        transactions.removeAtIndex(index)
                    }
                }
                
                for transaction in transactions {
                    
                    if let id = transaction.purchaseObjectId {
                        
                        transaction.purchase = Purchase.query()?.getObjectWithId(id) as? Purchase
                    }
                }
                
                self.transactions = transactions
                self.hasLoadedFirstTime = true
            }
            
        }, completion: { () -> () in
            
            refreshControl?.endRefreshing()
            self.tableView.reloadData()
            
            self.view.hideLoader()
            self.showOrHideTableOrNoDataView()
            
            //just in case
            self.loadMoreView.hideLoader()
            
            self.findAndScrollToCalculatedSelectedCellAtIndexPath()
            
            completion?()
        })
    }
    
    func findAndScrollToCalculatedSelectedCellAtIndexPath() {
        
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
                
                rowToDeselect = nil // for now (needsto get id from postback)
                
                if transactions.count > 0 {
                    
                    tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Middle, animated: false)
                }
            }
            if let indexPath = rowToDeselect {
                
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                
                NSTimer.schedule(delay: kAnimationDuration, handler: { timer in

                    var cellRect = self.tableView.rectForRowAtIndexPath(indexPath)
                    
                    let rectToCheck = CGRect(x: self.tableView.bounds.origin.x, y: self.tableView.bounds.origin.y + 64, width: self.tableView.bounds.width, height: self.tableView.bounds.height - 64)
                    
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
        
        selectedTransactionID = nil
        selectedPurchaseID = nil
        selectedRow = nil
        didJustDelete = false
    }
    
    override func refresh(refreshControl: UIRefreshControl?) {
        
        selectedTransactionID = nil
        selectedPurchaseID = nil
        selectedRow = nil
        didJustDelete = false
        
        //getDifferenceAndRefreshIfNeccessary(refreshControl)
        
        executeActualRefreshByHiding(false, refreshControl: refreshControl, take: nil, completion: nil)
    }
    
    func animateTableFooterViewHeight(height: Int, completion: (() -> ())?) {
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            
            self.loadMoreView.frame = CGRect(x: 0, y: 0, width: 0, height: height)
            self.tableView.tableFooterView = self.loadMoreView
            
        }) { (success) -> Void in
            
            completion?()
        }
    }
    
    func loadMore() {
        
        if !isLoadingMore && canLoadMore && hasLoadedFirstTime {
            
            isLoadingMore = true
            canLoadMore = false
            
            animateTableFooterViewHeight(kLoaderTableFooterViewHeight, completion: nil)
            
            loadMoreView.showLoader()
            
            query?.cancel()
            query?.skip = transactions.count + 1
            query?.limit = 16
            
            query?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if let transactions = objects as? [Transaction] {
                    
                    for transaction in transactions {
                        
                        self.transactions.append(transaction)
                    }
                }
                
                self.tableView.reloadData()
                self.isLoadingMore = false
                self.loadMoreView.hideLoader()
                
                NSTimer.schedule(delay: 0.2, handler: { timer in
                    
                    self.animateTableFooterViewHeight(0, completion: { () -> () in
                    })
                })
            })
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
        
        presentViewController(v, animated: true, completion: nil)
    }
    
    override func setupTableViewConstraints(tableView: UITableView) {
        
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        tableView.addLeftConstraint(toView: view, attribute: NSLayoutAttribute.Left, relation: NSLayoutRelation.GreaterThanOrEqual, constant: -0)
        tableView.addRightConstraint(toView: view, attribute: NSLayoutAttribute.Right, relation: NSLayoutRelation.GreaterThanOrEqual, constant: -0)
        
        tableView.addWidthConstraint(relation: NSLayoutRelation.LessThanOrEqual, constant: kTableViewMaxWidth)
        
        tableView.addTopConstraint(toView: view, relation: .Equal, constant: 0)
        tableView.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        tableView.addCenterXConstraint(toView: view)
    }
    
    func setupLoadMoreView() {
        
        loadMoreView.frame = CGRect(x: 0, y: 0, width: 50, height: kLoaderTableFooterViewHeight)
        tableView.tableFooterView = loadMoreView
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        query?.cancel()
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
            
            return UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: identifier)
        })
        
        setTableViewCellAppearanceForBackgroundGradient(cell)
        
        let transaction = transactions[indexPath.row]
        
        var amount = transaction.localeAmount
        
        if let purchaseObjectId = transaction.purchaseObjectId {

            if let purchase = transaction.purchase {
                
                amount = purchase.amount
            }
            
            //let dateString:String = transaction.purchase.purchasedDate!.toString(DateFormat.Date.rawValue)
            cell.textLabel?.text = "\(transaction.title!)"
            cell.imageView?.image = kPurchaseImage
        }
        else {
            
            let dateString:String = transaction.transactionDate.toString(DateFormat.Date.rawValue)
            cell.textLabel?.text = "\(transaction.title!)"
            cell.imageView?.image = kTransactionImage
            
        }
        
        let tintColor = transaction.toUser?.objectId == User.currentUser()?.objectId ? AccountColor.positiveColor() : AccountColor.negativeColor()
        
        cell.detailTextLabel?.textColor = tintColor
        cell.imageView?.tintWithColor(tintColor)
        cell.detailTextLabel?.text = Formatter.formatCurrencyAsString(amount)
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
            v.transaction = transaction
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
        
        return CGFloat.min + (kDevice == .Pad ? 40 : 0)
    }
}

extension TransactionsViewController: UIPopoverPresentationControllerDelegate {
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        
        popoverViewController = nil
        deselectSelectedCell(tableView)
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
}

extension TransactionsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y;
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        //NSInteger result = maximumOffset - currentOffset;
        
        //if not at top
        let isAboveTop = scrollView.contentOffset.y + 64 <= 0
        
        // Change 10.0 to adjust the distance from bottom
        if (maximumOffset - currentOffset <= 00.0 && !isAboveTop) {
            
            loadMore()
        }
    }

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        self.canLoadMore = true
    }
}

extension TransactionsViewController: SaveItemDelegate {
    
    func itemDidGetDeleted() {
        
//        if let indexPath = selectedRow {
//            
//            let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
//            
//            let wasLastRow = indexPath.row + 1 == numberOfRows
//            
//            tableView.beginUpdates()
//            transactions.removeAtIndex(indexPath.row)
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
//            tableView.endUpdates()
//
//            getDifference(nil)
//            
//            if wasLastRow {
//                
//                //new last row 
//                let newLastRowIndexPath = NSIndexPath(forRow: indexPath.row - 1, inSection: 0)
//                tableView.reloadRowsAtIndexPaths([newLastRowIndexPath], withRowAnimation: UITableViewRowAnimation.None)
//            }
//        }
        
        didJustDelete = true
        itemDidChange()
    }
    
    func itemDidChange() {
        
        executeActualRefreshByHiding(true, refreshControl: nil, take: transactions.count, completion: nil)
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