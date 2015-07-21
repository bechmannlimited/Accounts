//
//  BoolSettingViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 15/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

protocol BoolSettingDelegate {
    
    func didSelectBoolWithIdentifier(identifier: String, value: Bool)
}

class BoolSettingViewController: ACBaseViewController {

    var data = [true, false]
    var identifier = ""
    var tableView = UITableView()
    var delegate: BoolSettingDelegate?
    var currentValue: Bool = false
    
    convenience init(identifier: String, currentValue: Bool, title: String) {
        self.init()
        
        self.identifier = identifier
        self.currentValue = currentValue
        self.title = title
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

extension BoolSettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        
        cell.textLabel?.text = "\(data[indexPath.row])"
        cell.accessoryType = data[indexPath.row] == currentValue ? .Checkmark : .None
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        delegate?.didSelectBoolWithIdentifier(identifier, value: data[indexPath.row])
        navigationController?.popViewControllerAnimated(true)
    }
}