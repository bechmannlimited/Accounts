//
//  AccountFormViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit

class ACFormViewController: FormViewController {

    var blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
    var gradient: CAGradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = kViewBackgroundColor
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceivePushNotification:", name: kNotificationCenterPushNotificationKey, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupView()
        shouldAdjustTableViewInsetsForKeyboard = kDevice != .Pad
    }
    
    func didReceivePushNotification(notification: NSNotification) {
        
        
    }

    func setupNavigationBarAppearance() {
        
        blurView.removeFromSuperview()
        
        if let navigationController = navigationController{
            
            let frame = navigationController.navigationBar.frame
            
            blurView.frame = CGRect(x: frame.origin.x, y: -frame.origin.y, width: frame.width, height: frame.height + frame.origin.y)
        }
        
        navigationController?.navigationBar.addSubview(blurView)
    }
    
    func done() {
        
        view.endEditing(true)
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
}

extension ACFormViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return kTableViewCellHeight
    }
    
//    func scrollViewDidScroll(scrollView: UIScrollView) {
//        
//        view.endEditing(true)
//    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let c = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if let cell = c as? FormViewTextFieldCell {
            
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
            toolbar.tintColor = kNavigationBarTintColor
            
            var items = [UIBarButtonItem]()
            
            if cell.config.formCellType == .DatePicker {
                
                items.append(UIBarButtonItem(title: "Now", style: .Plain, target: cell, action: "setDateToToday"))
            }
            
            items.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil))
            items.append(UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done"))
            
            cell.datePicker?.backgroundColor = kNavigationBarBarTintColor
            
            toolbar.items = items
            cell.textField.inputAccessoryView = toolbar
        }
        
        return c
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
        
        if let cell = cell as? FormViewTextFieldCell {

            cell.textField.addTarget(self, action: "replaceNormalSpacesWithNonBreakingSpaces:", forControlEvents: UIControlEvents.EditingChanged)
        }
    }
    
    func replaceNormalSpacesWithNonBreakingSpaces(textField: UITextField) {
        
        textField.text = textField.text.replaceString(" ", withString: "\u{00a0}")
    }
}