//
//  WordsViewController.swift
//  MNISTer
//
//  Created by William McGinty on 7/23/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class WordsViewController: UIViewController {
    
 let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple, .cyan]
    
    fileprivate var visionCaptureController: VisionCaptureController!
    fileprivate var classificationManager: ClassificationManager!
    
    @IBOutlet fileprivate var cameraOutputView: UIView!
    @IBOutlet fileprivate var resultsView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet weak var resultLabel: UILabel!
    
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
        
        DispatchQueue.main.async() {
            self.resultsView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            let validResults = result.flatMap { $0 }
            
            //Classification
            
            if let input = self.visionCaptureController.capturedSnapshot?.oriented(forExifOrientation: 6), let characterBoxes = validResults.first?.characterBoxes {
            
                //self.stackView.subviews.forEach { $0.removeFromSuperview() }
                
                
                let gImages = self.glyphImages(for: characterBoxes, from: input)
                
                if let img = gImages.first {
                    try? self.classificationManager.prediction(from: img, completion: { classifiedImage, request, _ in
                        //Ensure that we have both ClassificationObservations and that have at least 1
                        guard let observations = request.results as? [VNClassificationObservation] else { fatalError("unexpected result type from VNCoreMLRequest") }
                        guard let best = observations.first else { fatalError("can't get best result") }
                        
                        DispatchQueue.main.async {
                            self.imageView.image = UIImage(ciImage:classifiedImage)
                            self.resultLabel.text = best.identifier + " ?"
                        }
                    })
                }
//                let imgViews: [UIImageView] = gImages.map {
//                    let imgView = UIImageView(image: UIImage(ciImage: $0))
//                    imgView.contentMode = .scaleAspectFit
//
//                    return imgView
//                }
//
//
//                imgViews.forEach { self.stackView.addArrangedSubview($0) }

                
//                let transform = CGAffineTransform(translationX: input.extent.midX, y: input.extent.midY)
//                    .rotated(by: .pi * -0.5)
//                    .translatedBy(x: -input.extent.midX, y: -input.extent.midY)
               // self.imageView.image = UIImage(ciImage: input.transformed(by: transform))
                
                //let img = self.glyphImage(for: first.first!, from: input)
                //self.imageView.image = UIImage(ciImage: corrected)
                
                //let classifiableImage = self.prepareClassifiableImage(from: input, with: rect)!
            
//                try? self.classificationManager.prediction(from: classifiableImage) { classifiedImage, request, error in
//                    //Ensure that we have both ClassificationObservations and that have at least 1
//                    guard let observations = request.results as? [VNClassificationObservation] else { fatalError("unexpected result type from VNCoreMLRequest") }
//                    guard let best = observations.first else { fatalError("can't get best result") }
//
//                    DispatchQueue.main.async {
//                        self.imageView.image = UIImage(ciImage:classifiedImage)
//                        self.resultLabel.text = best.identifier + " ?"
//                    }
//                }
            }
            
            // Word/Character highlighting in the scene
            for observation in validResults {
                if let boxes = observation.characterBoxes {
                    
                    VisionOutputFormatter.highlightWord(boundedBy: boxes, in: self.resultsView, with: .black)
                    for (index, characterBox) in boxes.enumerated() {
                        VisionOutputFormatter.highlightLetter(boundedBy: characterBox, in: self.resultsView,
                                                              with: self.colors[index % self.colors.count])
                    }
                }
            }
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
fileprivate extension WordsViewController {
    
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

