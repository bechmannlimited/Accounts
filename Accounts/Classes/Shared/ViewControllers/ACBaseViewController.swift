//
//  ACBaseViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit

class ACBaseViewController: BaseViewController {

    var blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
    var gradient: CAGradientLayer = CAGradientLayer()
    
    var activeQueries = [PFQuery?]()
    var toolbar = UIToolbar()
    
    var refreshUpdatedDate: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = kViewBackgroundColor
    }
    
    func appDidResume() {
        
        refresh(nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupView()
        
        if shouldShowLightTheme() {
            
            showLightTheme()
        }
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidResume", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func didReceivePushNotification(notification: NSNotification) {
        
        //println("hi")
    }
    
    func setupNavigationBarAppearance() {
        
        blurView.removeFromSuperview()
        
        if let navigationController = navigationController{
            
            let frame = navigationController.navigationBar.frame
            
            blurView.frame = CGRect(x: frame.origin.x, y: -frame.origin.y, width: frame.width, height: frame.height + frame.origin.y)
        }
        
        navigationController?.navigationBar.addSubview(blurView)
    }
    
    override func setupTableViewConstraints(tableView: UITableView) {
        
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        tableView.addLeftConstraint(toView: view, attribute: NSLayoutAttribute.Left, relation: NSLayoutRelation.GreaterThanOrEqual, constant: 0)
        tableView.addRightConstraint(toView: view, attribute: NSLayoutAttribute.Right, relation: NSLayoutRelation.GreaterThanOrEqual, constant: 0)
        
        tableView.addWidthConstraint(relation: NSLayoutRelation.LessThanOrEqual, constant: kTableViewMaxWidth)
        
        tableView.addTopConstraint(toView: view, relation: .Equal, constant: 0)
        tableView.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        tableView.addCenterXConstraint(toView: view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradient.frame = view.frame
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        for query in activeQueries {
            
            query?.cancel()
        }
    }
    
    func setupTextLabelForSaveStatusInToolbarWithLabel() {
        
        let label = UILabel()
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.numberOfLines = 2
        toolbar.addSubview(label)
        
        label.fillSuperView(UIEdgeInsets(top: 5, left: 15, bottom: -5, right: -40))
        
        label.font = UIFont(name: "HelveticaNeue-Light", size: 13)
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.textColor = UIColor.lightGrayColor()
        
        let setLabelText: () -> () = {
            
            if let date = self.refreshUpdatedDate {
                
                label.text = "Last synced \(date.readableFormattedStringForDateRange())"
            }
        }
        
        setLabelText()
        NSTimer.schedule(repeatInterval: 1, handler: { timer in
            
            setLabelText()
        })
    }
}

extension ACBaseViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return kTableViewCellHeight
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
        
        setTableViewCellAppearanceForBackgroundGradient(cell)
        
        if shouldShowLightTheme() {
            
            setupCellForLightTheme(cell)
        }
    }
}