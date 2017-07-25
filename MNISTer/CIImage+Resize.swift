//
//  CIImage+Resize.swift
//  MNISTer
//
//  Created by William McGinty on 7/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import Foundation
import CoreImage

extension CIImage {
    
    func resizedImage(with newSize: CGSize) -> CIImage? {
        let scale = Double(newSize.width) / Double(extent.size.width)
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: scale), forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey:kCIInputAspectRatioKey)
        let outputImage = filter.value(forKey: kCIOutputImageKey) as? CIImage
        
        return outputImage
    }
}
