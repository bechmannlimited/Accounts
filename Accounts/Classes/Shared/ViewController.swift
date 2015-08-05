//
//  ViewController.swift
//  bouncy_tableview
//
//  Created by Alex Bechmann on 29/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BouncyViewDelegate {
    
    var tableView = UITableView()
    var headerView = BouncyHeaderView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.frame = view.frame
        view.addSubview(tableView)
        
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        tableView.delegate = self
        tableView.dataSource = self

        headerView.setupHeaderWithOriginView(view, originTableView: tableView)
        headerView.setupTitle("Alex owes £15.00")
        headerView.getHeroImage("http://www.tvchoicemagazine.co.uk/sites/default/files/imagecache/interview_image/intex/michael_emerson.png")
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refresh(r: UIRefreshControl){
        
        NSTimer.schedule(delay: 1) { timer in
            
            r.endRefreshing()
        }
    }
    
    
    //
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = "Hello"
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 24
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        headerView.scrollViewDidScroll(scrollView)
    }
}

protocol BouncyViewDelegate{
    
    //func bouncyView(bouncyView: BouncyView, recommendedContentInsetForOriginTableView: UIEdgeInsets)
}

private let kTitlePadding: CGFloat = 15

