//
//  MultiCurrencyTableViewDelegate.swift
//  Accounts
//
//  Created by Alex Bechmann on 22/10/2015.
//  Copyright © 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class MultiCurrencyTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    var tableCellHeight:CGFloat = 30
    var results = Dictionary<String, NSNumber>()
    var friend = User()
    var textColor: UIColor?
    
    func calculatedHeight() -> CGFloat {
        
        return CGFloat(results.keys.count) * self.tableCellHeight
    }
    
    
    // MARK: - TableView Delegate
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell") { (identifier) -> (UITableViewCell) in
            
            return multiCurrencyTableViewCell(style: .Value1, reuseIdentifier: identifier)
        }
        
        let currencyId = Array(results.keys)[indexPath.row]
        let currency = Currency.CurrencyFromNSNumber(NSNumber(integer: Int(currencyId)!))
        let amount = Double(results[currencyId]!)
        
        if amount > 0 {
            
            cell.textLabel?.text = "Owes you"
        }
        else{
            
            cell.textLabel?.text = "You owe"
        }
        
        cell.detailTextLabel?.text = Formatter.formatCurrencyAsString(currency, value: abs(amount))
        cell.backgroundColor = UIColor.clearColor()
        tableView.backgroundColor = .clearColor()
        
        if let color = textColor {
            
            cell.textLabel?.textColor = color
            cell.detailTextLabel?.textColor = color
        }
        
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
        
        return results.count
    }
}

private class multiCurrencyTableViewCell: UITableViewCell {
    
    private override func setHighlighted(highlighted: Bool, animated: Bool) {
        
    }
}