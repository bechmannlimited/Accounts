//
//  FormViewButtonTableViewCell.swift
//  Pods
//
//  Created by Alex Bechmann on 08/06/2015.
//
//

import UIKit

public class FormViewButtonCell: FormViewCell {

    public var button = UIButton()
    
    override public func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        setupButton()
    }

    func setupButton() {
        
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.addSubview(button)
        button.fillSuperView(UIEdgeInsetsZero)
        
        button.setTitle(config.labelText, forState: UIControlState.Normal)
        
        if editable {
            
            button.addTarget(self, action: "buttonTapped", forControlEvents: UIControlEvents.TouchUpInside)
            
        }
        
        button.setTitleColor(config.buttonTextColor, forState: UIControlState.Normal)
    }
    
    func buttonTapped() {
        
        formViewDelegate?.formViewButtonTapped?(config.identifier)
        formViewDelegate?.formViewElementDidChange?(config.identifier, value: nil)
    }
}
