//
//  WordsViewController.swift
//  MNISTer
//
//  Created by William McGinty on 7/23/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit

class WordsViewController: UIViewController {
    
    fileprivate var videoFilter: CoreImageVideoFilter!
    fileprivate var detector: CIDetector!
    
    fileprivate let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .cyan, .purple]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create the video filter
        detector = CIDetector(ofType: CIDetectorTypeText, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        videoFilter = CoreImageVideoFilter(superview: view) { image in
            var resultImage = image
            let features = self.detector.features(in: image, options: [CIDetectorReturnSubFeatures:NSNumber(booleanLiteral: true)])
            for feature in features.prefix(1).flatMap({ $0 as? CITextFeature }) {
                let subFeatures = feature.subFeatures?.flatMap { $0 as? CITextFeature } ?? [CITextFeature]()
                for (index, subFeature) in subFeatures.enumerated() {
                    resultImage = self.drawHighlightOverlay(on: resultImage, with: self.colors[index % self.colors.count],
                                                            topLeft: subFeature.topLeft, topRight: subFeature.topRight,
                                                            bottomLeft: subFeature.bottomLeft, bottomRight: subFeature.bottomRight)
                }
            }
            
            return resultImage
        }
        videoFilter.startFiltering()
    }
}

//MARK: Helper
fileprivate extension WordsViewController {
    
    func drawHighlightOverlay(on image: CIImage, with color: UIColor,
                              topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var overlay = CIImage(color: CIColor(color: color.withAlphaComponent(0.5)))
        overlay = overlay.cropped(to: image.extent)
        overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent",
                                         parameters: [
                                            "inputExtent": CIVector(cgRect: image.extent),
                                            "inputTopLeft": CIVector(cgPoint: topLeft),
                                            "inputTopRight": CIVector(cgPoint: topRight),
                                            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                                            "inputBottomRight": CIVector(cgPoint: bottomRight)])
        return overlay.composited(over: image)
    }
}

