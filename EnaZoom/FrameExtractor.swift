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
    
    static let position = AVCaptureDevicePosition.back
    static let quality = AVCaptureSessionPreset3840x2160
    static let MAX_WIDTH = CGFloat(2160)
    static let MAX_HEIGHT = CGFloat(3840)

    static let MAX_ZOOM_FACTOR = 16.0
    static let MIN_ZOOM_FACTOR = 1.0
    static let MAX_SCALE = 4.0
    static let MIN_SCALE = 1.0
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    private var captureDevice: AVCaptureDevice?
    private var filterStage = 0
    private var filterList = ["none", "CIColorInvert", "CIPhotoEffectNoir", "CIFalseColor0", "CIFalseColor1"]
    
    private var positionX = CGFloat(0)
    private var positionY = CGFloat(0)
    
    private var zoomFactor = 1.0
    private var scale = FrameExtractor.MAX_SCALE
    
    weak var delegate: FrameExtractorDelegate?
    
    override init() {
        super.init()
        calculatePosition()
        
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
            
            /*
            do {
                try self.captureDevice?.lockForConfiguration()
                defer {self.captureDevice?.unlockForConfiguration()}
             
                self.captureDevice?.videoZoomFactor = CGFloat(self.zoomFactor)
                if (self.captureDevice?.hasTorch)! {
                    self.captureDevice?.torchMode = AVCaptureTorchMode.on
                }
            } catch {
                
            }
            */
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
        captureSession.sessionPreset = FrameExtractor.quality
        guard let captureDevice = selectCaptureDevice() else { return }
        self.captureDevice = captureDevice
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
        connection.isVideoMirrored = FrameExtractor.position == .front
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
    }
    
    private func applyFilter(ciImage: CIImage) -> CGImage {
        var cgImage: CGImage!
        
        switch (filterList[filterStage]) {
        case "none":
            cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
            break
        case "CIFalseColor0":
            let filter = CIFilter(name: "CIFalseColor")
            filter!.setValue(CIColor.blue(), forKey: "inputColor0")
            filter!.setValue(CIColor.yellow(), forKey: "inputColor1")
            filter!.setValue(ciImage, forKey: kCIInputImageKey)
            
            cgImage = context.createCGImage(filter!.value(forKey: kCIOutputImageKey) as! CIImage!, from: ciImage.extent)!
            break
        case "CIFalseColor1":
            let filter = CIFilter(name: "CIFalseColor")
            filter!.setValue(CIColor.yellow(), forKey: "inputColor0")
            filter!.setValue(CIColor.blue(), forKey: "inputColor1")
            filter!.setValue(ciImage, forKey: kCIInputImageKey)
            
            cgImage = context.createCGImage(filter!.value(forKey: kCIOutputImageKey) as! CIImage!, from: ciImage.extent)!
            break
        default:
            let filter = CIFilter(name: filterList[filterStage])
            filter!.setValue(ciImage, forKey: kCIInputImageKey)
            
            cgImage = context.createCGImage(filter!.value(forKey: kCIOutputImageKey) as! CIImage!, from: ciImage.extent)!
            break
        }
        
        return cgImage
    }
    
    private func cropImage(cgImage: CGImage) -> CGImage {
        calculatePosition()
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        let cropingRect: CGRect = CGRect(x: positionX, y: positionY, width: CGFloat(scale) * screenWidth, height: CGFloat(scale) * screenHeight)
        let cropedImage: CGImage = cgImage.cropping(to: cropingRect)!
        
        return cropedImage
    }
    
    private func calculatePosition() {
        positionX = CGFloat((FrameExtractor.MAX_WIDTH / 2) - ((CGFloat(scale) / 2) * UIScreen.main.bounds.width))
        positionY = CGFloat((FrameExtractor.MAX_HEIGHT / 2) - ((CGFloat(scale) / 2) * UIScreen.main.bounds.height))
    }
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // Unsharp Mask
        /*
        let usmFilter = CIFilter(name: "CIUnsharpMask")
        usmFilter!.setValue(ciImage, forKey: kCIInputImageKey)
        cgImage = context.createCGImage(usmFilter!.value(forKey: kCIOutputImageKey) as! CIImage!, from: ciImage.extent)!
         */
        
        let cgImage = applyFilter(ciImage: ciImage)
        let cropedImage = cropImage(cgImage: cgImage)
        let uiImage = UIImage(cgImage: cropedImage)
        
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
        filterStage = (filterStage + 1 >= filterList.count) ? 0 : filterStage + 1
    }
    
    func prevFilter() {
        filterStage = (filterStage - 1 < 0) ? filterList.count - 1 : filterStage - 1
    }
    
    func toggleTorch() {
        do {
            try self.captureDevice?.lockForConfiguration()
            defer {self.captureDevice?.unlockForConfiguration()}
            if (self.captureDevice?.hasTorch)! {
                self.captureDevice?.torchMode = (self.captureDevice?.torchMode == AVCaptureTorchMode.on) ? AVCaptureTorchMode.off : AVCaptureTorchMode.on
            }
        } catch {
            
        }
    }
    
    func move(x:CGFloat, y:CGFloat) {
        let newX = positionX - x
        let newY = positionY - y
        
        if (newX >= 0 && newX < (FrameExtractor.MAX_WIDTH - (CGFloat(scale) * UIScreen.main.bounds.width)) - 1) {
            positionX = newX
        }
        
        if (newY >= 0 && newY < (FrameExtractor.MAX_HEIGHT - (CGFloat(scale) * UIScreen.main.bounds.height)) - 1) {
            positionY = newY
        }
        
        print(positionX, positionY)
    }
    
    func zoom() {
        if (scale > FrameExtractor.MIN_SCALE) {
            scale /= 2
        } else if (zoomFactor < FrameExtractor.MAX_ZOOM_FACTOR) {
            zoomFactor *= 2
        } else {
            zoomFactor = FrameExtractor.MIN_ZOOM_FACTOR
            scale = FrameExtractor.MAX_SCALE
        }
        
        print(zoomFactor * (FrameExtractor.MAX_SCALE / scale))
        
        do {
            try self.captureDevice?.lockForConfiguration()
            defer {self.captureDevice?.unlockForConfiguration()}
            
            self.captureDevice?.videoZoomFactor = CGFloat(zoomFactor)
        } catch {
            
        }
    }
}
