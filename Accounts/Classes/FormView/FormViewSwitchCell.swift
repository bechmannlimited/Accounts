//
//  FormViewSwitchCell.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/10/2015.
//  Copyright © 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class FormViewSwitchCell: FormViewCell {

    let uiswitch = UISwitch()
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        textLabel?.text = config.labelText
        
        let uiswitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        uiswitch.on = (config.value as? Bool) == true
        uiswitch.addTarget(self, action: Selector("switchChanged:"), forControlEvents: UIControlEvents.ValueChanged)
        
        accessoryView = uiswitch
        uiswitch.userInteractionEnabled = editable
    }

    func switchChanged(cellSwitch: UISwitch) {
        
        //config.value = cellSwitch.on
        formViewDelegate?.formViewSwitchChanged(config.identifier, on: cellSwitch.on)
        formViewDelegate?.formViewElementDidChange(config.identifier, value: cellSwitch.on)
    }
}
