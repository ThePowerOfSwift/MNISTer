//
//  ViewController.swift
//  MNISTer
//
//  Created by William McGinty on 6/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import CoreML
import ImageIO
import CoreImage
import Vision

class ViewController: UIViewController {
    
    //MARK: Interface
    @IBOutlet fileprivate var imageView: UIImageView!
    @IBOutlet fileprivate var tempImageView: UIImageView!
    @IBOutlet fileprivate var classifiedImageView: UIImageView!
    @IBOutlet fileprivate var resultLabel: UILabel!
    @IBOutlet fileprivate var classifierSwitch: UISwitch!
    
    //MARK: Properties
    fileprivate var swiped = false
    fileprivate var lastPoint: CGPoint?
    
    //MARK: Classification
    lazy var mnistClassificationRequest: VNCoreMLRequest = {
        let model = try! VNCoreMLModel(for: MNISTClassifier().model)
        return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
    }()

    lazy var emnistClassificationRequest: VNCoreMLRequest = {
        let model = try! VNCoreMLModel(for: EMNISTClassifier().model)
        return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
    }()
    
    //MARK: Drawing
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(predictDigitFromDrawing), object: nil)
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: tempImageView)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first, let lastPoint = lastPoint {
            let current = touch.location(in: tempImageView)
            drawLine(from: lastPoint, to: current)
            
            self.lastPoint = current
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped, let lastPoint = lastPoint {
            drawLine(from: lastPoint, to: lastPoint)
        }
        
        UIGraphicsBeginImageContext(imageView.frame.size)
        imageView.image?.draw(in: CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height), blendMode: .normal, alpha: 1)
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: tempImageView.frame.width, height: tempImageView.frame.height), blendMode: .normal, alpha: 1)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        tempImageView.image = nil
		
		perform(#selector(predictDigitFromDrawing), with: nil, afterDelay: 0.75)
    }
}

//MARK: Reset
extension ViewController {
    
    @IBAction func resetPressed() {
        imageView.image = nil
        resultLabel.text = "Write Something"
        classifiedImageView.image = nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard event?.subtype == .motionShake else { return }
        resetPressed()
    }
}

//MARK: Classification
fileprivate extension ViewController {
    
	@objc func predictDigitFromDrawing() {
        
        //First we need to resize the image to the model's desired size (in this case 28x28 points)
        guard let uiImage = imageView.image?.resizedImage(with: CGSize(width: 28, height: 28)) else { return }
        
        //Next, we'll create a CIImage and apply a series of modifications - orientation (top left is origin, desaturation, and color inversion. This resulting image will appear just above the classification).
        guard let ciImage = CIImage(image: uiImage) else { return }
        let correctedImage = ciImage
			.oriented(forExifOrientation: 1)
			.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 32
                ])
			.applyingFilter("CIColorInvert", parameters: [:])
        DispatchQueue.main.async { self.classifiedImageView.image = UIImage(ciImage: correctedImage) }
        
        //Finally we'll create an image request handler wih our correct image, and attempt to perform the classification request instance variable.
        let handler = VNImageRequestHandler(ciImage: correctedImage)
        do {
            //This classification request calls back to 'handleClassification' when complete
            try handler.perform([currentClassificationRequest])
            resultLabel.text = "..."
        } catch {
            print(error)
        }
    }
    
    func handleClassification(request: VNRequest, error: Error?) {
        
        //Ensure that we have both ClassificationObservations and that have at least 1
        guard let observations = request.results as? [VNClassificationObservation] else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let best = observations.first else { fatalError("can't get best result") }
        
        DispatchQueue.main.async {
            if best.confidence > 0.7 {
                self.resultLabel.text = "Classification: \(best.identifier)?"
            } else {
                self.resultLabel.text = "???"
            }
        }
    }
}

//MARK: Helper
fileprivate extension ViewController {
    func drawLine(from source: CGPoint, to destination: CGPoint) {
        
        UIGraphicsBeginImageContext(tempImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: tempImageView.frame.width, height: tempImageView.frame.height))
        
        context?.move(to: source)
        context?.addLine(to: destination)
        
        context?.setLineCap(.round)
        context?.setLineWidth(20.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setBlendMode(.normal)
        
        context?.strokePath()
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    var currentClassificationRequest: VNCoreMLRequest {
        return classifierSwitch.isOn ? emnistClassificationRequest : mnistClassificationRequest
    }
}

