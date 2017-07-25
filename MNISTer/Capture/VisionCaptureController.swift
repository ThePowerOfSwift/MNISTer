//
//  VisionCaptureController.swift
//  MNISTer
//
//  Created by William McGinty on 7/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VisionCaptureController: NSObject {
    
    fileprivate(set) var captureController: CaptureController!
    fileprivate var currentBuffer: CVPixelBuffer?
    var requests: [VNRequest]
    
    public init(superview: UIView, requests: [VNRequest] = []) throws {
        self.requests = requests
        super.init()
        
        captureController = try CaptureController(superview: superview) { [unowned self] buffer in
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
            self.currentBuffer = pixelBuffer
            
            var requestOptions: [VNImageOption : Any] = [VNImageOption : Any]()
            if let cameraData = CMGetAttachment(buffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
                requestOptions[.cameraIntrinsics] = cameraData
            }
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
            do {
                try requestHandler.perform(self.requests)
            } catch {
                print(error)
            }
        }
    }
    
    func startRunning() {
        captureController.startRunning()
    }
    
    func stopRunning() {
        captureController.stopRunning()
    }
    
    var capturedSnapshot: CIImage? {
        return currentBuffer.map { CIImage(cvPixelBuffer: $0) }
    }
}
