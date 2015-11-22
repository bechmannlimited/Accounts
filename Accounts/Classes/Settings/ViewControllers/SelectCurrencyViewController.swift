//
//  SelectCurrencyViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

protocol SelectCurrencyDelegate {
    
    func didSelectCurrencyId(id: NSNumber)
}

class SelectCurrencyViewController: ACBaseViewController, UITableViewDataSource {

    var tableView = UITableView()
    var data = [0 : "GBP", 1: "EUR", 2: "USD", 3: "DKK"]
    var delegate: SelectCurrencyDelegate?
    var previousValue:NSNumber?
    
    convenience init(previousValue: NSNumber?) {
        
        self.init()
        self.previousValue = previousValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView(tableView, delegate: self, dataSource: self)
    }

    override func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension SelectCurrencyViewController {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
        
        let currencyId = indexPath.row
        
        cell.textLabel?.text = data[currencyId]
        
        if previousValue != nil && currencyId == Int(previousValue!){
            
            cell.accessoryType = .Checkmark
        }
        else {
            
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let currencyId = NSNumber(integer: indexPath.row)
        
        delegate?.didSelectCurrencyId(currencyId)
        
        tableView.reloadData()
        
        navigationController?.popViewControllerAnimated(true)
    }
}