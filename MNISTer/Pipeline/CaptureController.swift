//
//  CaptureController.swift
//  MNISTer
//
//  Created by William McGinty on 7/24/17.
//  Copyright © 2017 William McGinty. All rights reserved.
//

import UIKit
import AVFoundation

class CaptureController: NSObject {
    
    fileprivate var session: AVCaptureSession!
    fileprivate let sessionQueue = DispatchQueue(label: "SessionQueue")
    fileprivate(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
    fileprivate let sampleBufferHandler: SampleBufferHandler
    
    public typealias SampleBufferHandler = (CMSampleBuffer) -> Void
    public init(superview: UIView, bufferHandler: @escaping SampleBufferHandler) throws {
        sampleBufferHandler = bufferHandler
        super.init()
        
        session = try createAVSession(with: superview)
    }
    
    func startRunning() {
        session.startRunning()
    }
    
    func stopRunning() {
        session.stopRunning()
    }
}

//MARK: Helper
fileprivate extension CaptureController {
    
    func createAVSession(with outputView: UIView) throws -> AVCaptureSession {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        try? captureDevice?.lockForConfiguration()
        captureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 15)
        captureDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 15)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resize
        layer.frame = outputView.bounds
        outputView.layer.addSublayer(layer)
        previewLayer = layer
        
        return session
    }
}

//MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension CaptureController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        sampleBufferHandler(sampleBuffer)
    }
}
