//
//  PurchaseOrTransactionViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 19/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
 
private let kAddFriendImage = AppTools.iconAssetNamed("973-user-toolbar.png")

class SelectPurchaseOrTransactionViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    
    var data = [
        (identifier: "Transaction", textLabelText: "Add an i.o.u", footer: "Add an iou if you owe one of your friends some money, or if they owe you.", image: kIouImage),
        (identifier: "Purchase", textLabelText: "Split a bill", footer: "Split a bill if someone paid the full price for something, on behalf of multiple others.", image: kPurchaseImage),
        (identifier: "TransactionPayment", textLabelText: "Add a payment", footer: "Add a payment to log when you paid or got paid by one of your friends.", image: kPaymentImage),
        (identifier: "Invites", textLabelText: "Add a friend", footer: User.currentUser()?.descriptionForHowToAddAsFriend(), image: kAddFriendImage)
    ]

    var contextualFriend: User?
    var saveItemDelegate: SaveItemDelegate?
    var isInsidePopover = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView(tableView, delegate: self, dataSource: self)
        tableView.setEditing(true, animated: false)
        tableView.allowsSelectionDuringEditing = true
        
        addCloseButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        saveItemDelegate?.newItemViewControllerWasPresented(nil)
    }
    
    override func close() {
        super.close()
        
        navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(navigationController!.popoverPresentationController!)
    }
    
    override func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension SelectPurchaseOrTransactionViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return data.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
        
        cell.textLabel?.text = data[indexPath.section].textLabelText
        cell.imageView?.image = data[indexPath.section].image
        cell.imageView?.tintWithColor(AccountColor.blueColor())

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let identifier = data[indexPath.section].identifier
        
        if identifier == "Purchase" {
            
            let v = SavePurchaseViewController()
            
            if let friend = contextualFriend {
                
                let transaction = Transaction()
                transaction.fromUser = User.currentUser()
                transaction.toUser = friend

                v.isInsidePopover = kDevice == .Pad
                v.purchase.transactions = []
                v.purchase.transactions.append(transaction)
            }
            
            v.delegate = saveItemDelegate
            saveItemDelegate?.newItemViewControllerWasPresented(v)
            
            navigationController?.pushViewController(v, animated: true)
        }
        else if identifier == "Transaction" || identifier == "TransactionPayment" {
            
            let v = SaveTransactionViewController()
            
            if let friend = contextualFriend {
                
                v.transaction.toUser = friend
            }
            
            if identifier == "TransactionPayment" {
                
                v.transaction.type = TransactionType.payment
            }

            v.isInsidePopover = kDevice == .Pad
            v.delegate = saveItemDelegate
            saveItemDelegate?.newItemViewControllerWasPresented(v)
            
            navigationController?.pushViewController(v, animated: true)
        }
        else if identifier == "Invites" {
            
            let v = FriendInvitesViewController()
            navigationController?.pushViewController(v, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return UITableViewCellEditingStyle.Insert
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.delegate?.tableView?(tableView, didSelectRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        return data[section].footer
    }
}