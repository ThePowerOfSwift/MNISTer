//
//  Utilities.swift
//  MNISTer
//
//  Created by William McGinty on 7/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import CoreGraphics
import ImageIO

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImageOrientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

extension CIImage {
    
    func rotatingAroundCenter(by angle: CGFloat) -> CIImage {
        let transform = CGAffineTransform(translationX: extent.midX, y: extent.midY)
            .rotated(by: .pi * -0.5)
            .translatedBy(x: -extent.midX, y: -extent.midY)
        return transformed(by: transform)
    }
}
