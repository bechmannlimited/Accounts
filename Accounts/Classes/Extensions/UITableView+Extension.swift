//
//  UITableView+Extension.swift
//  Pods
//
//  Created by Alex Bechmann on 08/06/2015.
//
//

import UIKit

public extension UITableView {
    
    public func dequeueOrCreateReusableCellWithIdentifier(identifier: String, requireNewCell: (identifier: String) -> (UITableViewCell)) -> UITableViewCell {
        
        if let dequeuedCell = dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell {
            
            return dequeuedCell
        }
        else {
            
            return requireNewCell(identifier: identifier)
        }
    }
}