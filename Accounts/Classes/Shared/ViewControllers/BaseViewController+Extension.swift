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
    
    func setTableViewCellAppearanceForBackgroundGradient(cell:UITableViewCell) {
    
//        cell.backgroundColor = kTableViewCellBackgroundColor
//        cell.textLabel?.textColor = kTableViewCellTextColor
//        cell.tintColor = kTableViewCellTintColor
    }
    
    func isInsidePopover() -> Bool {

        return view.frame != UIScreen.mainScreen().bounds
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