//
//  BaseViewController+Extension.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit

extension BaseViewController {
    
    func setupView() {
        
        view.backgroundColor = kViewBackgroundColor
        setNavigationControllerToDefault()
    }
    
    func addCloseButton() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: "close")
    }
    
    func close() {
        
        dismissViewControllerFromCurrentContextAnimated(true)
    }
    
    func setBackgroundGradient() -> CAGradientLayer {
        
        var gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [kViewBackgroundGradientTop.CGColor, kViewBackgroundGradientBottom.CGColor]
        //view.layer.insertSublayer(gradient, atIndex: 0)
        
        return gradient
    }
    
    func setTableViewAppearanceForBackgroundGradient(tableView: UITableView) {
        
        //tableView.separatorStyle = kTableViewCellSeperatorStyle
        //tableView.separatorColor = kTableViewCellSeperatorColor
//        tableView.backgroundColor = kTableViewBackgroundColor
    }
    
    func setLightThemeForTableView(tableView:UITableView) {
        
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorColor = UIColor.lightGrayColor()
    }
    
    func showLightTheme() {
        
        //navigationController?.popoverPresentationController?.backgroundColor = UIColor.whiteColor()
        navigationController?.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        navigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(UIColor.whiteColor().colorWithAlphaComponent(0.95), size: CGSize(width: 10, height: 10)), forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.tintColor = AccountColor.greenColor()
        view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
    }
    
    func setNavigationControllerToDefault(){
        
        navigationController?.navigationBar.tintColor = kNavigationBarTintColor
        navigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(kNavigationBarBarTintColor, size: CGSize(width: 10, height: 10)), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = kDefaultNavigationBarShadowImage
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    func setTableViewCellAppearanceForBackgroundGradient(cell:UITableViewCell) {
    
        cell.textLabel?.textColor = .whiteColor()
        
        if let cell = cell as? FormViewTextFieldCell {
            
            cell.label.textColor = .whiteColor()
        }
        else if let cell = cell as? FriendTableViewCell {
            
            cell.friendNameLabel.textColor = .whiteColor()
        }
    }
    
    func setupCellForLightTheme(cell: UITableViewCell) {
        
        cell.backgroundColor = UIColor.whiteColor()
        cell.textLabel?.textColor = UIColor.blackColor()
        cell.detailTextLabel?.textColor = UIColor.lightGrayColor()
        
        if let cell = cell as? FormViewTextFieldCell {
            
            cell.label.textColor = UIColor.blackColor()
            cell.textField.textColor = UIColor.lightGrayColor()
        }
        
        cell.tintColor = AccountColor.blueColor()
    }
    
    func isInsidePopover() -> Bool {

        return view.frame != UIScreen.mainScreen().bounds
    }
    
    func shouldShowLightTheme() -> Bool {
        
        return false
    }
    
    func setupNoDataLabel(noDataView:UILabel, text: String) {
        
        noDataView.text = text
        noDataView.font = UIFont(name: "HelveticaNeue-Light", size: 30)
        noDataView.textColor = UIColor.lightGrayColor()
        noDataView.lineBreakMode = NSLineBreakMode.ByWordWrapping
        noDataView.numberOfLines = 0
        noDataView.textAlignment = NSTextAlignment.Center
        
        noDataView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(noDataView)
        noDataView.fillSuperView(UIEdgeInsets(top: 40, left: 40, bottom: -40, right: -40))
        noDataView.layer.opacity = 0
    }
}

extension BaseViewController: UITableViewDelegate {
    
    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // Warning: - no super
        
        let numberOfRowsInSections:Int = tableView.numberOfRowsInSection(indexPath.section)
    
        cell.layer.mask = nil
        
        if view.bounds.width > kTableViewMaxWidth && !tableView.editing {
            
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