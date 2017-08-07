//
//  LetterViewController.swift
//  MNISTer
//
//  Created by William McGinty on 6/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import Vision

class LetterViewController: UIViewController {
    
    //MARK: Interface
    @IBOutlet fileprivate var illustratorView: IllustratorView!
    @IBOutlet fileprivate var classifiedImageView: UIImageView!
    @IBOutlet fileprivate var resultLabel: UILabel!
    @IBOutlet fileprivate var classifierSwitch: UISwitch!
    
    //MARK: Properties
    fileprivate var swiped = false
    fileprivate var lastPoint: CGPoint?
    
    //MARK: Classification
    lazy var mnistClassifier = ClassificationManager(model: MNISTClassifier().model, inputRequirements: ModelInputRequirements(size: CGSize(width: 28, height: 28)))
    lazy var emnistClassifier = ClassificationManager(model: EMNISTClassifier().model, inputRequirements: ModelInputRequirements(size: CGSize(width: 28, height: 28)))
    var currentClassifier: ClassificationManager { return classifierSwitch.isOn ? emnistClassifier : mnistClassifier }
}

//MARK: Touch Handling
extension LetterViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(predictDigitFromDrawing), object: nil)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        perform(#selector(predictDigitFromDrawing), with: nil, afterDelay: 0.75)
    }
}

//MARK: Reset
extension LetterViewController {
    
    @IBAction func resetPressed() {
        illustratorView.resetCanvas()
        resultLabel.text = "Write Something"
        classifiedImageView.image = nil
    }

    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard event?.subtype == .motionShake else { return }
        resetPressed()
    }
}

//MARK: Classification
fileprivate extension LetterViewController {
    
    @objc func predictDigitFromDrawing() {
        guard let image = illustratorView.current else { return }

        try? currentClassifier.prediction(from: image) { classifiedImage, request, error in
            DispatchQueue.main.async {
                //TODO: This image doesn't look correct anymore. IllustratorView bug? Or ClassificationManager?
                self.classifiedImageView.image = UIImage(ciImage: classifiedImage)
            }

            //Ensure that we have both ClassificationObservations and that have at least 1
            guard let observations = request.results as? [VNClassificationObservation] else { fatalError("unexpected result type from VNCoreMLRequest") }
            guard let best = observations.first else { fatalError("can't get best result") }

            DispatchQueue.main.async {
                self.resultLabel.text = "Classification: \(best.confidence > 0.7 ? best.identifier : "?")?"
            }
        }
    }
}

