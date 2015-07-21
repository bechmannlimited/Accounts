//
//  UIView+Animations.swift
//  Pods
//
//  Created by Alex Bechmann on 31/05/2015.
//
//

import UIKit

public extension UIView {

    public func animateConstraintChange(duration: NSTimeInterval) {
        
        UIView.animateWithDuration(duration, animations: { () in
            self.layoutIfNeeded()
        })
    }
    
    public func showLoader() {
        
        var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, 50, 50)) as UIActivityIndicatorView
        actInd.center = self.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        actInd.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(actInd)
        actInd.addCenterYConstraint(toView: self)
        actInd.addCenterXConstraint(toView: self)
        actInd.startAnimating()
    }
    
    public func hideLoader() {
        for v in self.subviews {
            if v is UIActivityIndicatorView{
                v.stopAnimating()
            }
        }
    }
}
