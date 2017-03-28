//
//  FrameExtractor.swift
//  EnaZoom
//
//  Created by Seehait Chockthanyawat on 3/28/17.
//  Copyright © 2017 Seehait Chockthanyawat. All rights reserved.
//

import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    func captured(image: UIImage)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    
    private let position = AVCaptureDevicePosition.back
    private let quality = AVCaptureSessionPreset3840x2160
    private let MAX_WIDTH = CGFloat(2160)
    private let MAX_HEIGHT = CGFloat(3840)
    private let SCALE = CGFloat(4)
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    private var captureDevice: AVCaptureDevice?
    private var filterStage = 0
    private var filterList = ["none", "CIColorInvert", "CIColorPosterize"]
    
    private var positionX = CGFloat(0)
    private var positionY = CGFloat(0)
    
    weak var delegate: FrameExtractorDelegate?
    
    override init() {
        super.init()
        positionX = CGFloat((MAX_WIDTH / 2) - ((SCALE / 2) * UIScreen.main.bounds.width))
        positionY = CGFloat((MAX_HEIGHT / 2) - ((SCALE / 2) * UIScreen.main.bounds.height))
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
            
            do {
                try self.captureDevice?.lockForConfiguration()
                defer {self.captureDevice?.unlockForConfiguration()}
                
                self.captureDevice?.videoZoomFactor = CGFloat(8.0)
                if (self.captureDevice?.hasTorch)! {
                    self.captureDevice?.torchMode = AVCaptureTorchMode.on
                }
            } catch {
                
            }
        }
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return }
        self.captureDevice = captureDevice
        do {
            try captureDevice.lockForConfiguration()
            defer {captureDevice.unlockForConfiguration()}
            
            if captureDevice.hasTorch {
                captureDevice.torchMode = AVCaptureTorchMode.on
            }
        } catch {
            
        }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        guard let connection = videoOutput.connection(withMediaType: AVFoundation.AVMediaTypeVideo) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        /*return AVCaptureDevice.devices().filter {
         ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) &&
         ($0 as AnyObject).position == position
         }.first as? AVCaptureDevice*/
        return AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
    }
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        var cgImage: CGImage
        
        if (filterStage == 0) {
            cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
        } else {
            let filter = CIFilter(name: filterList[filterStage])
            filter!.setValue(ciImage, forKey: kCIInputImageKey)
            
            cgImage = context.createCGImage(filter!.value(forKey: kCIOutputImageKey) as! CIImage!, from: ciImage.extent)!
        }
        
        /*
         let imgWidth = cgImage.width
         let imgHeight = cgImage.height
         */
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        let cropingRect: CGRect = CGRect(x: positionX, y: positionY, width: SCALE * screenWidth, height: SCALE * screenHeight)
        let cropedImage: CGImage = cgImage.cropping(to: cropingRect)!
        
        let uiImage = UIImage(cgImage: cropedImage)
        
        
        // let uiImage = UIImage(cgImage: cgImage)
        
        return uiImage
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(image: uiImage)
        }
    }
    
    func nextFilter() {
        if (filterStage + 1 >= filterList.count) {
            filterStage = 0
        } else {
            filterStage = filterStage + 1
            
        }
    }
    
    func prevFilter() {
        if (filterStage - 1 < 0) {
            filterStage = filterList.count - 1
        } else {
            filterStage = filterStage - 1
        }
    }
    
    func toggleTorch() {
        do {
            try self.captureDevice?.lockForConfiguration()
            defer {self.captureDevice?.unlockForConfiguration()}
            
            self.captureDevice?.videoZoomFactor = CGFloat(16.0)
            if (self.captureDevice?.hasTorch)! {
                self.captureDevice?.torchMode = (self.captureDevice?.torchMode == AVCaptureTorchMode.on) ? AVCaptureTorchMode.off : AVCaptureTorchMode.on
            }
        } catch {
            
        }
    }
    
    func move(x:CGFloat, y:CGFloat) {
        let newX = positionX - x
        let newY = positionY - y
        
        if (newX >= 0 && newX < (MAX_WIDTH - (SCALE * UIScreen.main.bounds.width)) - 1) {
            positionX = newX
        }
        
        if (newY >= 0 && newY < (MAX_HEIGHT - (SCALE * UIScreen.main.bounds.height)) - 1) {
            positionY = newY
        }
        
        print(positionX, positionY)
    }
}
