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
    
    var delegate: SaveItemDelegate?
    
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
            
            UIAlertController.showAlertControllerWithButtonTitle("Go back", confirmBtnStyle: UIAlertActionStyle.Destructive, message: askToPopMessage) { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
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

}
