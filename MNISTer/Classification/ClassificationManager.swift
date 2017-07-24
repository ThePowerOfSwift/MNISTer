//
//  EMNISTClassificationManager.swift
//  MNISTer
//
//  Created by William McGinty on 7/23/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import Vision
import CoreImage

public struct ModelInputRequirements {
    let size: CGSize
}

class ClassificationManager {
    
    public let model: VNCoreMLModel
    public let inputRequirements: ModelInputRequirements
    
    public init(model: MLModel, inputRequirements: ModelInputRequirements) throws {
        self.model = try VNCoreMLModel(for: model)
        self.inputRequirements = inputRequirements
    }
    
    public typealias RequestCompletionHandler = (_ classifiedImage: CIImage, _ request: VNRequest, _ error: Error?) -> Void
    public func prediction(from image: UIImage, completion: @escaping RequestCompletionHandler) throws {
        
        //First we need to resize the image to the model's desired size
        guard let resizedImage = image.resizedImage(with: inputRequirements.size) else { return }
        
        //Next, we create a CIImage and apply a series of modifications.
        guard let inputImage = CIImage(image: resizedImage) else { return }
        
        let correctedImage = inputImage
            .oriented(forExifOrientation: 1)
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey : 0, kCIInputContrastKey : 32])
            .applyingFilter("CIColorInvert", parameters: [:])
        
        //Finally, run this request through Vision
        let handler = VNImageRequestHandler(ciImage: correctedImage)
        do {
            try handler.perform([VNCoreMLRequest(model: model) { request, error in
                completion(correctedImage, request, error)
            }])
        } catch {
            throw error
        }
    }
}
