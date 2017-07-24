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
    lazy var mnistClassifier = ClassificationManager(model: MNISTClassifier().model, inputRequirements: ModelInputRequirements(size: CGSize(width: 28, height: 28)))
    lazy var emnistClassifier = ClassificationManager(model: EMNISTClassifier().model, inputRequirements: ModelInputRequirements(size: CGSize(width: 28, height: 28)))
    
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
        guard let image = imageView.image else { return }
        
        resultLabel.text = "..."
        try? currentClassifier.prediction(from: image) { classifiedImage, request, error in
            
            DispatchQueue.main.async { self.classifiedImageView.image = UIImage(ciImage: classifiedImage) }
            
            //Ensure that we have both ClassificationObservations and that have at least 1
            guard let observations = request.results as? [VNClassificationObservation] else { fatalError("unexpected result type from VNCoreMLRequest") }
            guard let best = observations.first else { fatalError("can't get best result") }
            
            DispatchQueue.main.async {
                self.resultLabel.text = "Classification: \(best.identifier)?"
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
    
    var currentClassifier: ClassificationManager {
        return classifierSwitch.isOn ? emnistClassifier : mnistClassifier
    }
}

