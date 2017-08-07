//
//  LiveViewController.swift
//  MNISTer
//
//  Created by William McGinty on 7/23/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class LiveViewController: UIViewController {
    
    let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple, .cyan]
    
    fileprivate var visionCaptureController: VisionCaptureController!
    fileprivate var classificationManager: ClassificationManager!
    
    @IBOutlet fileprivate var cameraOutputView: UIView!
    @IBOutlet fileprivate var resultsView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet weak var resultLabel: UILabel!
    
    let context = CIContext(options: nil)
    
    lazy var textDetectionRequests: [VNRequest] = {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        
        return [textRequest]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        visionCaptureController = try! VisionCaptureController(superview: cameraOutputView, requests: textDetectionRequests)
        visionCaptureController.startRunning()
        
        classificationManager = try! ClassificationManager(model: EMNISTClassifier().model, inputRequirements: ModelInputRequirements(size: CGSize(width: 28, height: 28)))
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else { return }
        let result = observations.map { $0 as? VNTextObservation }
        let validResults = result.flatMap { $0 }
        
        DispatchQueue.main.async() {
            self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
           
            guard let input = self.visionCaptureController.capturedSnapshot else { return }
            guard let firstResult = validResults.first else { return }
            guard let cBoxes = firstResult.characterBoxes else { return }
            
            let extractor = GlyphExtractor(inputImage: input, exifOrientation: 6)
            let glyphs = extractor.glyphImages(for: cBoxes)
            
            glyphs.forEach {
                let image = UIImage(cgImage: self.context.createCGImage($0, from: $0.extent)!)
                let imageView = UIImageView(image: image)
                self.stackView.addArrangedSubview(imageView)
            }
            
            // Word/Character highlighting in the scene
            self.cameraOutputView.layer.sublayers?.forEach {
                if $0 is AVCaptureVideoPreviewLayer { return }
                $0.removeFromSuperlayer()
            }
            
            for observation in validResults {
                if let boxes = observation.characterBoxes {
                    
                    VisionOutputFormatter.highlightWord(boundedBy: boxes, in: self.cameraOutputView, with: .black)
                    for (index, characterBox) in boxes.enumerated() {
                        VisionOutputFormatter.highlightLetter(boundedBy: characterBox, in: self.cameraOutputView,
                                                              with: self.colors[index % self.colors.count])
                    }
                }
            }
            
//            self.visionCaptureController.stopRunning()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//                self.visionCaptureController.startRunning()
//            })
        }
    }
    
    public func prepareClassifiableImage(from inputImage: CIImage, with detectedRectangle: VNRectangleObservation) -> CIImage? {
        let imageSize = inputImage.extent.size
        
        // Verify detected rectangle is valid.
        let boundingBox = detectedRectangle.boundingBox.scaled(to: imageSize)
        guard inputImage.extent.contains(boundingBox)
            else { print("invalid detected rectangle"); return nil }
        
        // Rectify the detected image and reduce it to inverted grayscale for applying model.
        let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
        let topRight = detectedRectangle.topRight.scaled(to: imageSize)
        let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
        let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
        let correctedImage = inputImage
            .cropped(to: boundingBox)
            .applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)
                ])
        .rotatingAroundCenter(by: .pi / 2)
        
        return correctedImage
    }
}
//MARK: Helper
fileprivate extension LiveViewController {
    
    func glyphImage(for observation: VNRectangleObservation, from inputImage: CIImage) -> CIImage {
        
        let boundingBox = observation.boundingBox.scaled(to: inputImage.extent.size)
        
        // Rectify the detected image and reduce it to inverted grayscale for applying model.
        let topLeft = observation.topLeft.scaled(to: inputImage.extent.size)
        let topRight = observation.topRight.scaled(to: inputImage.extent.size)
        let bottomLeft = observation.bottomLeft.scaled(to: inputImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: inputImage.extent.size)
        let correctedImage = inputImage
            .cropped(to: boundingBox)
            .applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)
                ])
        
        return correctedImage
    }
    

    func glyphImages(for observations: [VNRectangleObservation], from image: CIImage) -> [CIImage] {
        return observations.map {
            let xCoord = $0.topLeft.x * image.extent.size.width
            let yCoord = (1 - $0.topLeft.y) * image.extent.size.height
            return image.cropped(to: CGRect(x: xCoord, y: yCoord,
                                            width: image.extent.width * $0.boundingBox.width,
                                            height: image.extent.height * $0.boundingBox.height))
        }
    }
}

