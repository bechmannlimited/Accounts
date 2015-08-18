//
//  SaveItemViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 21/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import SwiftOverlays

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
        
        removeLoadingViews()
    }
    
    func askToPopIfChanged() {
        
        if isSaving {
            
            return
        }
        
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
        
        removeLoadingViews()
        navigationItem.leftBarButtonItem?.enabled = true
    }
    
    func showLoadingOverlayWithText(text: String) {
        
        //SwiftOverlays.showBlockingWaitOverlayWithText(text)
        self.showWaitOverlayWithText(text)
    }
    
    func updateUIForSavingOrDeleting() {
        
        tableView.userInteractionEnabled = false
        isSaving = true
        showOrHideSaveButton()
        tableView.hidden = false
        navigationItem.leftBarButtonItem?.enabled = false
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
    
    func showSavingOverlay() {
        
        showLoadingOverlayWithText("Saving...")
    }
    
    func showDeletingOverlay() {
        
        showLoadingOverlayWithText("Deleting...")
    }

    func removeLoadingViews() {
        
        SwiftOverlays.removeAllBlockingOverlays()
        self.removeAllOverlays()
    }
}

extension SaveItemViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
    
        cell.textLabel?.font = UIFont.normalFont(cell.textLabel!.font.pointSize)
        cell.detailTextLabel?.font = UIFont.lightFont(cell.detailTextLabel!.font.pointSize)
    }
}
