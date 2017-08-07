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
    
    var letterboxed: UIImage? {
        guard size.width != size.height else { return self }
        let squareSize = max(size.width, size.height)
        
        UIGraphicsBeginImageContext(CGSize(width: squareSize, height: squareSize))
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context?.fill(CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
        draw(in: CGRect(x: (squareSize - size.width) * 0.5, y: (squareSize - size.height) * 0.5, width: size.width, height: size.height))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
