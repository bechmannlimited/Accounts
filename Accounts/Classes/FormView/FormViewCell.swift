//
//  FormViewCell.swift
//  Pods
//
//  Created by Alex Bechmann on 08/06/2015.
//
//

import UIKit

public class FormViewCell: UITableViewCell {

    public var config = FormViewConfiguration()
    public var formViewDelegate: FormViewDelegate?
    
    public var editable: Bool {
        get {
         
            if let editable = formViewDelegate?.formViewElementIsEditable?(config.identifier) {
                
                return editable
            }
            
            return true
        }
    }
}
