//
//  BaseViewController.swift
//  Pods
//
//  Created by Alex Bechmann on 30/05/2015.
//
//

import UIKit

@objc protocol BaseViewControllerDelegate {
    
    func preferredNavigationBar()
}

enum ConstraintReference {
    
    case None
    case Top
    case Left
    case Right
    case Bottom
}

public class BaseViewController: UIViewController {
    
    var tableViews: Array<UITableView> = []
    
    public var refreshRequest: JsonRequest?
    
    var tableViewConstraints = Dictionary<ConstraintReference, NSLayoutConstraint>()
    var tableViewOriginalInsetInfo = Dictionary<UITableView, (contentInset: UIEdgeInsets, scrollIndicatorInsets: UIEdgeInsets)>()
    
    public var shouldDeselectCellOnViewWillAppear = true
    public var shouldAdjustTableViewInsetsForKeyboard = false
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        if shouldDeselectCellOnViewWillAppear {
            
            for tableView in tableViews {
                
                deselectSelectedCell(tableView)
                
//                var navigationBarHeight:CGFloat = 0
//                
//                if let navigationBar = navigationController?.navigationBar {
//                    
//                    navigationBarHeight = navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.size.height
//                }
//                
//                let originalContentInset = tableViewOriginalInsetInfo[tableView]!.contentInset
//                let originalScrollIndicatorInsets = tableViewOriginalInsetInfo[tableView]!.scrollIndicatorInsets
//                
//                tableView.contentInset = UIEdgeInsets(top: originalContentInset.top + navigationBarHeight, left: originalContentInset.left, bottom: originalContentInset.bottom, right: originalContentInset.right)
//                tableView.scrollIndicatorInsets = UIEdgeInsets(top: originalScrollIndicatorInsets.top + navigationBarHeight, left: originalScrollIndicatorInsets.left, bottom: originalScrollIndicatorInsets.bottom, right: originalScrollIndicatorInsets.right)
            }
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        refreshRequest?.cancel()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource:UITableViewDataSource) {
        
        view.addSubview(tableView)
        
        setupTableViewConstraints(tableView)
        
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableViews.append(tableView)
        
        tableViewOriginalInsetInfo[tableView] = (contentInset: tableView.contentInset, scrollIndicatorInsets: tableView.scrollIndicatorInsets)
        
        tableView.reloadData()
    }
    
    public func setupTableViewRefreshControl(tableView: UITableView) {
        
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.AllEvents)
        tableView.addSubview(refreshControl)
    }
    
    public func setupTableViewConstraints(tableView: UITableView) {
        
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let constraints = tableView.fillSuperView(UIEdgeInsetsZero)
        tableViewConstraints[.Top] = constraints[0]
        tableViewConstraints[.Left] = constraints[1]
        tableViewConstraints[.Bottom] = constraints[2]
        tableViewConstraints[.Right] = constraints[3]
    }
    
    public func refresh(refreshControl: UIRefreshControl?) {
        
    }
    
    public func deselectSelectedCell(tableView: UITableView) {
        
        if let indexPath = tableView.indexPathForSelectedRow() {
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    //MARK: - Dismiss view controller
    
    public func dismissViewControllerFromCurrentContextAnimated(animated: Bool) {
        
        if navigationController?.viewControllers.count > 1 {
            
            navigationController?.popViewControllerAnimated(animated)
        }
        else {
            
            dismissViewControllerAnimated(animated, completion: nil)
        }
    }
    
    //MARK: - Notification methods
    
    func keyboardDidChangeFrame(notification:NSNotification) {
        
        if shouldAdjustTableViewInsetsForKeyboard {
            
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
                
                var navigationBarHeight:CGFloat = 0
                
                if let navigationBar = navigationController?.navigationBar {
                    
                    navigationBarHeight = navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.size.height
                }
                
                for tableView in tableViews {
                    
                    let originalContentInset = tableViewOriginalInsetInfo[tableView]!.contentInset
                    let originalScrollIndicatorInsets = tableViewOriginalInsetInfo[tableView]!.scrollIndicatorInsets
                    
                    if keyboardSize.origin.y == UIScreen.mainScreen().bounds.size.height {
                        
                        tableView.contentInset = UIEdgeInsets(top: originalContentInset.top + navigationBarHeight, left: originalContentInset.left, bottom: originalContentInset.bottom, right: originalContentInset.right)
                        tableView.scrollIndicatorInsets = UIEdgeInsets(top: originalScrollIndicatorInsets.top + navigationBarHeight, left: originalScrollIndicatorInsets.left, bottom: originalScrollIndicatorInsets.bottom, right: originalScrollIndicatorInsets.right)
                        
                    } else {
                        
                        let bottomOffset = keyboardSize.height
                        
                        tableView.contentInset = UIEdgeInsetsMake(originalContentInset.top + navigationBarHeight, originalContentInset.left, bottomOffset, originalContentInset.right)
                        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(originalScrollIndicatorInsets.top + navigationBarHeight, originalScrollIndicatorInsets.left, bottomOffset, originalScrollIndicatorInsets.right)
                    }
                    
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }
        }
    }
}

