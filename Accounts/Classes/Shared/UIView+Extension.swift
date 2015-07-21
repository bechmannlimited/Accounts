//
//  UIView+Extension.swift
//  Accounts
//
//  Created by Alex Bechmann on 19/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

extension UIView {
    
    func roundCorners(corners: UIRectCorner, cornerRadiusSize: CGSize) {
        
        var rounded: UIBezierPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: cornerRadiusSize)
        
        var shape = CAShapeLayer()
        shape.path = rounded.CGPath
        layer.mask = shape
    }
}
