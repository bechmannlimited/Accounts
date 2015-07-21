//
//  UIViewExtensions.swift
//
//
//  Created by Shagun Madhikarmi on 09/10/2014.
//  Copyright (c) 2014 madhikarma. All rights reserved.
//

import Foundation
import UIKit

/**
Extension of UIView for AutoLayout helper methods
*/
public extension UIView {
    
    
    // Mark: - Fill
    
    public func fillSuperView(edges: UIEdgeInsets) -> [NSLayoutConstraint] {
        
        var topConstraint: NSLayoutConstraint = self.addTopConstraint(toView: self.superview, relation: .Equal, constant: edges.top)
        var leftConstraint: NSLayoutConstraint = self.addLeftConstraint(toView: self.superview, relation: .Equal, constant: edges.left)
        var bottomConstraint: NSLayoutConstraint = self.addBottomConstraint(toView: self.superview, relation: .Equal, constant: edges.bottom)
        var rightConstraint: NSLayoutConstraint = self.addRightConstraint(toView: self.superview, relation: .Equal, constant: edges.right)
        
        return [topConstraint, leftConstraint, bottomConstraint, rightConstraint]
    }
    
    
    // MARK: - Left Constraints
    
    public func addLeftConstraint(toView view: UIView?, attribute: NSLayoutAttribute, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .Left, toView: view, attribute: attribute, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    public func addLeftConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addLeftConstraint(toView: view, attribute: .Left, relation: relation, constant: constant)
    }
    
    
    // MARK: - Right Constraints
    
    public func addRightConstraint(toView view: UIView?, attribute: NSLayoutAttribute, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .Right, toView: view, attribute: attribute, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    public func addRightConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addRightConstraint(toView: view, attribute: .Right, relation: relation, constant: constant)
    }
    
    
    // MARK: - Top Constraints
    
    public func addTopConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addTopConstraint(toView: view, attribute: .Top, relation: relation, constant: constant)
    }
    
    public func addTopConstraint(toView view: UIView?, attribute: NSLayoutAttribute, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .Top, toView: view, attribute: attribute, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    public func addTopMarginConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addTopMarginConstraint(toView: view, attribute: .TopMargin, relation: relation, constant: constant)
    }
    
    public func addTopMarginConstraint(toView view: UIView?, attribute: NSLayoutAttribute, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .TopMargin, toView: view, attribute: attribute, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    
    // MARK: - Bottom Constraints
    
    public func addBottomConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addBottomConstraint(toView: view, attribute: .Bottom, relation: relation, constant: constant)
    }
    
    public func addBottomConstraint(toView view: UIView?, attribute: NSLayoutAttribute, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .Bottom, toView: view, attribute: attribute, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    public func addBottomMarginConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .BottomMargin, toView: view, attribute: .Bottom, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    public func addBottomMarginConstraint(toView view: UIView?, attribute: NSLayoutAttribute, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addBottomConstraint(toView: view, attribute: .BottomMargin, relation: relation, constant: constant)
    }
    
    
    // MARK: - Center X Constraint
    
    public func addCenterXConstraint(toView view: UIView?) -> NSLayoutConstraint {
        
        return self.addCenterXConstraint(toView: view, relation: .Equal, constant: 0)
    }
    
    public func addCenterXConstraint(toView view: UIView?, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addCenterXConstraint(toView: view, relation: .Equal, constant: constant)
    }
    
    public func addCenterXConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .CenterX, toView: view, attribute: .CenterX, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    
    // MARK: - Center Y Constraint
    
    public func addCenterYConstraint(toView view: UIView?) -> NSLayoutConstraint {
        
        return self.addCenterYConstraint(toView: view, relation: .Equal, constant: 0)
    }
    
    public func addCenterYConstraint(toView view: UIView?, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addCenterYConstraint(toView: view, relation: .Equal, constant: constant)
    }
    
    public func addCenterYConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .CenterY, toView: view, attribute: .CenterY, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    
    // MARK: - Width Constraints
    
    public func addWidthConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .Width, toView: view, attribute: .Width, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
    }
    
    public func addWidthConstraint(relation relation1: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addWidthConstraint(toView: nil, relation: relation1, constant: constant)
    }
    
    
    // MARK: - Height Constraints
    
    public func addHeightConstraint(toView view: UIView?, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint = self.createConstraint(attribute: .Height, toView: view, attribute: .Height, relation: relation, constant: constant)
        self.superview?.addConstraint(constraint)
        
        return constraint
        
    }
    
    public func addHeightConstraint(relation relation1: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        return self.addHeightConstraint(toView: nil, relation: relation1, constant: constant)
    }
    
    
    // MARK: - Private
    
    private func createConstraint(attribute attr1: NSLayoutAttribute, toView: UIView?, attribute attr2: NSLayoutAttribute, relation: NSLayoutRelation, constant: CGFloat) -> NSLayoutConstraint {
        
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: attr1,
            relatedBy: relation,
            toItem: toView,
            attribute: attr2,
            multiplier: 1.0,
            constant: constant)
        
        return constraint
    }
}