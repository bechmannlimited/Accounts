//
//  UIImage+Extension.swift
//  Pods
//
//  Created by Alex Bechmann on 31/05/2015.
//
//

import Foundation

public extension UIImage {
    
    public class func imageWithColor(color:UIColor, size:CGSize) -> UIImage
    {
        UIGraphicsBeginImageContext(size)
        var rPath:UIBezierPath = UIBezierPath(rect:CGRectMake(0.0, 0.0, size.width, size.height))
        color.setFill()
        rPath.fill()
        var image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}