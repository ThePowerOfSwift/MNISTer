//
//  WordViewController.swift
//  MNISTer
//
//  Created by William McGinty on 8/5/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import Vision

class WordViewController: UIViewController {
    
    @IBOutlet fileprivate var illustratorView: IllustratorView!
    @IBOutlet fileprivate var characterHighlightContainerView: UIView!
    @IBOutlet fileprivate var resultLabel: UILabel!
    
    let context = CIContext(options: nil)
    
    lazy var emnistClassifier = ClassificationManager(model: EMNISTClassifier().model, inputRequirements: ModelInputRequirements(size: CGSize(width: 28, height: 28)))
    fileprivate var glyphExtractor: GlyphExtractor?
    var result: [String]? {
        didSet {
            DispatchQueue.main.async { self.resultLabel.text = self.result?.reduce("", +) }
        }
    }
}

//MARK: Interface Actions
extension WordViewController {
    
    @IBAction func classifyDrawing() {
        guard let image = illustratorView.current, let ciImage = CIImage(image: image) else { return }
        
        glyphExtractor = GlyphExtractor(image: image)
        let request = VNDetectTextRectanglesRequest(completionHandler: handleClassification)
        request.reportCharacterBoxes = true
        
        let requestHandler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try requestHandler.perform([request])
        } catch {
            print(error)
        }
    }
}

//MARK: Reset
extension WordViewController {
    
    @IBAction func resetPressed() {
        illustratorView.resetCanvas()
        characterHighlightContainerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        resultLabel.text = "Write Something"
    }
}

//MARK: Classifiation
fileprivate extension WordViewController {
    
    var colors: [UIColor] { return [.red, .orange, .yellow, .green, .blue, .purple, .cyan] }
    
    func handleClassification(request: VNRequest, error: Error?) {
        DispatchQueue.global(qos: .userInteractive).async {
            guard let observations = request.results else { self.resultLabel.text = "No idea..."; return }
            let results = observations.flatMap { $0 as? VNTextObservation }
            let characterBoxes = Array(results.flatMap { $0.characterBoxes }.joined())
            
            DispatchQueue.main.async {
                characterBoxes.forEach { VisionOutputFormatter.highlightLetter(boundedBy: $0,
                                                                               in: self.characterHighlightContainerView, with: self.colors.random) }
            }
            
            guard let extractor = self.glyphExtractor else { return }
            let glyphs = extractor.glyphImages(for: characterBoxes)
            let resizedGlyphs: [CIImage] = glyphs.flatMap {
                //TODO: The speed of this... can be massively improved
                let image = UIImage(cgImage: self.context.createCGImage($0, from: $0.extent)!).letterboxed!
                return CIImage(image: image)
            }
            
            self.result = [String](repeating: "", count: resizedGlyphs.count)
            resizedGlyphs.enumerated().forEach { (index, value) in
                try? self.emnistClassifier.prediction(from: value) { image, request, error in
                    guard let observations = request.results as? [VNClassificationObservation] else { return }
                    guard let best = observations.first else { return }
                    
                    DispatchQueue.main.async {
                        self.result?[index] = best.identifier
                    }
                }
            }
        }
    }
}
