//
//  BaseViewController+Extension.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
 
import SwiftOverlays

extension BaseViewController {
    
    func setupView() {
        
        view.backgroundColor = kViewBackgroundColor
        navigationController?.view.backgroundColor = .whiteColor()
        setNavigationControllerToDefault()
    }
    
    func addCloseButton() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: "close")
    }
    
    func close() {
        
        dismissViewControllerFromCurrentContextAnimated(true)
    }
    
    func setNavigationControllerToDefault(){
        
        navigationController?.navigationBar.tintColor = kNavigationBarTintColor
        navigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(kNavigationBarBarTintColor, size: CGSize(width: 10, height: 10)), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = kDefaultNavigationBarShadowImage
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
//    func isInsidePopoverUsingTableView(tableView: UITableView) -> Bool {
//
//        return modalPresentationStyle == UIModalPresentationStyle.Popover
//        return popoverPresentationController?.arrowDirection != UIPopoverArrowDirection.Unknown && kDevice == .Pad
//    }
    
    func setupNoDataLabel(noDataView:UILabel, text: String, originView: UIView) {
        
        noDataView.text = text
        noDataView.font = UIFont.lightFont(30) //HelveticaNeue-Light
        noDataView.textColor = UIColor.lightGrayColor()
        noDataView.lineBreakMode = NSLineBreakMode.ByWordWrapping
        noDataView.numberOfLines = 0
        noDataView.textAlignment = NSTextAlignment.Center
        
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        originView.addSubview(noDataView)
        
        noDataView.addHeightConstraint(relation: .Equal, constant: 400)
        noDataView.addWidthConstraint(relation: .Equal, constant: 300)
        noDataView.addCenterXConstraint(toView: originView)
        noDataView.addTopConstraint(toView: originView, relation: .Equal, constant: 10)
        
        noDataView.layer.opacity = 0
    }
    
    func showSavingOverlay() {
        
        showLoadingOverlayWithText("Saving...")
    }
    
    func showDeletingOverlay() {
        
        showLoadingOverlayWithText("Deleting...")
    }
    
    func showLoadingOverlayWithText(text: String) {
        
        //SwiftOverlays.showBlockingWaitOverlayWithText(text)
        self.showWaitOverlayWithText(text)
    }
    
    func removeLoadingViews() {
        
        SwiftOverlays.removeAllBlockingOverlays()
        self.removeAllOverlays()
    }
}

extension BaseViewController: UITableViewDelegate {
    
    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // Warning: - no super
        
        let numberOfRowsInSections:Int = tableView.numberOfRowsInSection(indexPath.section)
    
        cell.layer.mask = nil
        
        if view.bounds.width > kTableViewMaxWidth && !tableView.editing {
            
            if indexPath.row == 0 {
                
                cell.roundCorners([UIRectCorner.TopLeft, UIRectCorner.TopRight], cornerRadiusSize: kTableViewCellIpadCornerRadiusSize)
            }
            
            if indexPath.row == numberOfRowsInSections - 1 {
                
                cell.roundCorners([UIRectCorner.BottomLeft, UIRectCorner.BottomRight], cornerRadiusSize: kTableViewCellIpadCornerRadiusSize)
            }
            
            if indexPath.row == 0 && indexPath.row == numberOfRowsInSections - 1 {
                
                cell.roundCorners(UIRectCorner.AllCorners, cornerRadiusSize: kTableViewCellIpadCornerRadiusSize)
            }
        }
        
        if let cell = cell as? FormViewTextFieldCell {
            
            cell.label.font = UIFont.normalFont(cell.label.font.pointSize)
            cell.textField.font = UIFont.lightFont(cell.textField.font!.pointSize)
        }
        else if let cell = cell as? FriendTableViewCell {
            
            cell.friendNameLabel.font = UIFont.normalFont(cell.friendNameLabel.font.pointSize)
            cell.amountOwedLabel.font =  UIFont.normalFont(cell.amountOwedLabel.font.pointSize)
        }
    }
    
    public func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {

            view.textLabel?.font = UIFont.lightFont(view.textLabel!.font!.pointSize)
            view.contentView.backgroundColor = kViewBackgroundColor
        }
    }
}