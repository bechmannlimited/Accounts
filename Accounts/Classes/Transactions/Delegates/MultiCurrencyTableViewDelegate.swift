//
//  MultiCurrencyTableViewDelegate.swift
//  Accounts
//
//  Created by Alex Bechmann on 22/10/2015.
//  Copyright © 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class MultiCurrencyTableViewDelegate: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var tableCellHeight:CGFloat = 38
    
    // MARK: - TableView Delegate
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell") { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: .Value1, reuseIdentifier: identifier)
        }
        
        cell.textLabel?.text = "You owe"
        cell.detailTextLabel?.text = "$10.00"
        
        cell.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0)
        tableView.backgroundColor = .clearColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return tableCellHeight
    }
    
    // MARK: - TableView DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return numberOfRowsInSection()
    }
    
    func numberOfRowsInSection() -> Int {
        
        return 2
    }
}
