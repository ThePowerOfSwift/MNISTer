//
//  UIImage+Orientation.swift
//  MNISTer
//
//  Created by William McGinty on 8/5/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import ImageIO

public extension UIImage {
    public var cgImageOrientation: CGImagePropertyOrientation? {
        switch imageOrientation {
        case .up: return CGImagePropertyOrientation(rawValue: 1)
        case .down: return CGImagePropertyOrientation(rawValue: 3)
        case .left: return CGImagePropertyOrientation(rawValue: 8)
        case .right: return CGImagePropertyOrientation(rawValue: 6)
        case .upMirrored: return CGImagePropertyOrientation(rawValue: 2)
        case .downMirrored: return CGImagePropertyOrientation(rawValue: 4)
        case .leftMirrored: return CGImagePropertyOrientation(rawValue: 5)
        case .rightMirrored: return CGImagePropertyOrientation(rawValue: 7)
        }
    }
}
