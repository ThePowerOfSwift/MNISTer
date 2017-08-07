//
//  GlyphExtractor.swift
//  MNISTer
//
//  Created by William McGinty on 7/23/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import CoreImage
import Vision

//
//  GlyphExtractor.swift
//  MNISTer
//
//  Created by William McGinty on 7/23/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import CoreImage
import Vision

public struct GlyphExtractor {
    
    public let inputImage: CIImage
    
    public init?(image: UIImage) {
        guard let orientation = image.cgImageOrientation else { return  nil }
        self.init(inputImage: CIImage(image: image)!, exifOrientation: Int32(orientation.rawValue))
    }
    
    public init(inputImage: CIImage, exifOrientation: Int32) {
        self.inputImage = inputImage.oriented(forExifOrientation: exifOrientation)
    }
    
    //TODO: Add CIFeature support
    public func glyphImage(for observation: VNRectangleObservation) -> CIImage {
        let boundingBox = observation.boundingBox.scaled(to: inputImage.extent.size)
        return inputImage.cropped(to: boundingBox)
    }
    
    public func glyphImages(for observations: [VNRectangleObservation]) -> [CIImage] {
        return observations.map { glyphImage(for: $0) }
    }
}
