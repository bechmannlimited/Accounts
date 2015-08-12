//
//  SaveItemViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 21/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit

class SaveItemViewController: ACFormViewController {

    var itemDidChange = false
    var isSaving = false
    var allowEditing = false
    var askToPopMessage = ""
    //var copyOfItem = Dictionary<String, AnyObject?>()
    
    var delegate: SaveItemDelegate?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if kDevice == .Pad { // isInsidePopover() {
            
            navigationController?.popoverPresentationController?.backgroundColor = UIColor.clearColor()
            navigationController?.view.backgroundColor = UIColor.darkGrayColor()
            view.backgroundColor = UIColor.clearColor()
            println(isInsidePopover())
            tableView.backgroundColor = UIColor.clearColor()
        }
    }
    
    func pop() {
        
        self.dismissViewControllerFromCurrentContextAnimated(true)
        self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
    }
    
    func popAll() {
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(navigationController!.popoverPresentationController!)
    }
    
    func askToPopIfChanged() {
        
        if itemDidChange {
            
            UIAlertController.showAlertControllerWithButtonTitle("Discard", confirmBtnStyle: UIAlertActionStyle.Destructive, message: askToPopMessage) { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.onDiscard()
                    self.pop()
                }
            }
        }
        else {
            
            self.pop()
        }
    }
    
    func updateUIForServerInteraction() {
        
        tableView.userInteractionEnabled = false
        isSaving = true
        showOrHideSaveButton()
        tableView.hidden = true
        view.showLoader()
    }
    
    func updateUIForEditing() {
        
        tableView.userInteractionEnabled = true
        isSaving = false
        showOrHideSaveButton()
        tableView.hidden = false
        view.hideLoader()
        
    }
    
    func updateUIForSavingOrDeleting() {
        
        tableView.userInteractionEnabled = false
        isSaving = true
        showOrHideSaveButton()
        tableView.hidden = false
    }
    
    func showOrHideSaveButton() {
        
        if allowEditing {
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save")
            navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        }
        
        navigationItem.rightBarButtonItem?.enabled = saveButtonEnabled()
    }
    
    func saveButtonEnabled() -> Bool {
        
        return false
    }
    
    func onDiscard() {
        
        
    }

}
