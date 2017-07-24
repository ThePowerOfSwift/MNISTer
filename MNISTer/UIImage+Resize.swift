//
//  UIImage+Resize.swift
//  MNISTer
//
//  Created by William McGinty on 6/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit

extension UIImage {
    
    func resizedImage(with newSize: CGSize) -> UIImage? {
        guard self.size != newSize else { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage? {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height
        
        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }
        
        let newSize = CGSize(width: size.width/resizeFactor, height: size.height/resizeFactor)
        let resized = resizedImage(with: newSize)
        return resized
    }
    
}

extension UIImage
{
    var letterboxed: UIImage? {
        let width = self.size.width
        let height = self.size.height
        
        // no letterboxing needed, already a square
        if(width == height)
        {
            return self
        }
        
        // find the larger side
        let squareSize = max(width, height)
        
        UIGraphicsBeginImageContext(CGSize(width: squareSize, height: squareSize))
        
        // draw black background
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context?.fill(CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
        
        // draw image in the middle
        draw(in: CGRect(x: (squareSize - width) / 2, y: (squareSize - height) / 2, width: width, height: height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
