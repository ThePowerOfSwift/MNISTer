//
//  VisionOutputFormatter.swift
//  MNISTer
//
//  Created by William McGinty on 7/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import Vision

struct VisionOutputFormatter {
    
    static func highlightWord(boundedBy boxes: [VNRectangleObservation], in view: UIView, with color: UIColor) {
        var maxX: CGFloat = .infinity
        var minX: CGFloat = 0.0
        var maxY: CGFloat = .infinity
        var minY: CGFloat  = 0.0

        for char in boxes {
            if char.bottomLeft.x < maxX { maxX = char.bottomLeft.x }
            if char.bottomRight.x > minX { minX = char.bottomRight.x }
            if char.bottomRight.y < maxY { maxY = char.bottomRight.y }
            if char.topRight.y > minY { minY = char.topRight.y }
        }
        
        let xCord = maxX * view.frame.size.width
        let yCord = (1 - minY) * view.frame.size.height
        let width = (minX - maxX) * view.frame.size.width
        let height = (minY - maxY) * view.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = color.cgColor
        
        view.layer.addSublayer(outline)
    }
    
    static func highlightLetter(boundedBy box: VNRectangleObservation, in view: UIView, with color: UIColor) {
        let xCord = box.topLeft.x * view.frame.size.width
        let yCord = (1 - box.topLeft.y) * view.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * view.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * view.frame.size.height
        
        let overlay = CALayer()
        overlay.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        overlay.backgroundColor = color.withAlphaComponent(0.5).cgColor
        
        view.layer.addSublayer(overlay)
    }
}


