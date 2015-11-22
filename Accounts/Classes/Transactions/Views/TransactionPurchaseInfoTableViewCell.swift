//
//  TransactionPurchaseInfoTableViewCell.swift
//  Accounts
//
//  Created by Alex Bechmann on 03/09/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class TransactionPurchaseInfoTableViewCell: UITableViewCell {

    var transaction: Transaction = Transaction()
    var loadingView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    var button = UIButton()
    
    func setup() {

        self.textLabel?.text = "Current bill total"
        imageView?.image = kPurchaseImage
        imageView?.tintWithColor(AccountColor.blueColor())
        
        setupRetryButton()
        getPurchaseInfo()
    }
    
    func setupRetryButton() {
        
        button.setTitle("Retry", forState: UIControlState.Normal)
        button.addTarget(self, action: "getPurchaseInfo", forControlEvents: UIControlEvents.TouchUpInside)
        button.setTitleColor(AccountColor.blueColor(), forState: UIControlState.Normal)
        button.sizeToFit()
    }
    
    func setViewForRetry() {
        
        self.detailTextLabel?.text = "load failed..."
        accessoryView = button
    }
    
    func getPurchaseInfo() {
        
        loadingView.showLoader()
        accessoryView = loadingView
        detailTextLabel?.text = ""
        
        transaction.getPurchaseInfo({ (total, error) -> () in
            
            self.accessoryView = nil
            
            if error == nil {
 
                self.detailTextLabel?.text = Formatter.formatCurrencyAsString(self.transaction.currency(), value: total)
            }
            else {
                
                self.setViewForRetry()
            }
        })
    }
}
