//
//  WordsViewController.swift
//  MNISTer
//
//  Created by William McGinty on 7/23/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import Vision

class WordsViewController: UIViewController {
    
    @IBOutlet fileprivate var outputView: UIView!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    fileprivate var videoFilter: CoreImageVideoFilter!
    fileprivate var detector: CIDetector!
    
    fileprivate let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .cyan, .purple]
    
    lazy var classificationManager = ClassificationManager(model: EMNISTClassifier().model,
                                                                inputRequirements: ModelInputRequirements(size: CGSize(width: 28, height: 28)))
    
    lazy var emnistClassificationRequest: VNCoreMLRequest = {
        let model = try! VNCoreMLModel(for: EMNISTClassifier().model)
        return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create the video filter
        detector = CIDetector(ofType: CIDetectorTypeText, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        videoFilter = CoreImageVideoFilter(superview: outputView) { image in
            var resultImage = image
            let features = self.detector.features(in: image, options: [CIDetectorReturnSubFeatures:NSNumber(booleanLiteral: true)])
            for feature in features.prefix(1).flatMap({ $0 as? CITextFeature }) {
                let subFeatures = feature.subFeatures?.flatMap { $0 as? CITextFeature } ?? [CITextFeature]()
                
                //analyze
                let glyphs = Array(self.glyphImages(for: subFeatures, from: image))
                let letterboxed = glyphs.prefix(1).flatMap { $0.letterboxed }
                
                letterboxed.forEach { self.predictDigit(from: $0) }
                
                //draw
                for (index, subFeature) in subFeatures.prefix(1).enumerated() {
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

//MARK: Classification
fileprivate extension WordsViewController {
    
    func predictDigit(from image: UIImage) {
        
        //First we need to resize the image to the model's desired size (in this case 28x28 points)
        guard let uiImage = image.resizedImage(with: CGSize(width: 28, height: 28)) else { return }
        
        //Next, we'll create a CIImage and apply a series of modifications - orientation (top left is origin, desaturation, and color inversion. This resulting image will appear just above the classification).
        guard let ciImage = CIImage(image: uiImage) else { return }
        let correctedImage = ciImage
            .oriented(forExifOrientation: 1)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 32
                ])
            .applyingFilter("CIColorInvert", parameters: [:])
        
        DispatchQueue.main.async {
            self.imageView.image = UIImage(ciImage: correctedImage)
        }
        
        //Finally we'll create an image request handler wih our correct image, and attempt to perform the classification request instance variable.
        let handler = VNImageRequestHandler(ciImage: correctedImage)
        do {
            //This classification request calls back to 'handleClassification' when complete
            try handler.perform([emnistClassificationRequest])
        } catch {
            print(error)
        }
    }
    
    func handleClassification(request: VNRequest, error: Error?) {
        
        //Ensure that we have both ClassificationObservations and that have at least 1
        guard let observations = request.results as? [VNClassificationObservation] else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let best = observations.first else { fatalError("can't get best result") }
        
        DispatchQueue.main.async {
                print(best.identifier)
        }
    }
}

//MARK: Helper
fileprivate extension WordsViewController {
    
    func glyphImages(for subfeatures: [CITextFeature], from image: CIImage) -> [UIImage] {
        return subfeatures.map { feature in
            return image.cropped(to: CGRect(origin: feature.bottomLeft, size: feature.bounds.size))
                .transformed(by: CGAffineTransform(rotationAngle: .pi))
            }.map { UIImage(ciImage: $0) }
    }
    
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

