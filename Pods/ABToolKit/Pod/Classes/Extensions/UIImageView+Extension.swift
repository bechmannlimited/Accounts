//
//  UIImageView+Extension.swift
//  Pods
//
//  Created by Alex Bechmann on 31/05/2015.
//
//

import Foundation

public extension UIImageView {
    
    public func tintWithColor(color:UIColor) {
        
        self.image = self.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.tintColor = color
    }
    
    public func removeTint() {
        
        self.image = self.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
    }
}