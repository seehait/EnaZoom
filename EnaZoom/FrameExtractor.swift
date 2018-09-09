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

public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    static let POSITION = AVCaptureDevicePosition.back
    static var QUALITY = AVCaptureSessionPreset3840x2160
    static var MAX_WIDTH = CGFloat(2160)
    static var MAX_HEIGHT = CGFloat(3840)

    static let MAX_ZOOM_FACTOR = 16.0
    static let MIN_ZOOM_FACTOR = 1.0
    static var MAX_SCALE = 4.0
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
        initCameraResolution()
        calculatePosition()
        
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    private func initCameraResolution() {
        let modelName = UIDevice.current.modelName
        switch modelName {
        case "iPhone 4", "iPad 2":
            FrameExtractor.QUALITY = AVCaptureSessionPreset1280x720
            FrameExtractor.MAX_WIDTH = CGFloat(720)
            FrameExtractor.MAX_HEIGHT = CGFloat(1280)
            FrameExtractor.MAX_SCALE = 1
            scale = 1
            break;
        case "iPhone 4s", "iPhone 5", "iPhone 5c", "iPhone 5s", "iPhone 6", "iPhone 6 Plus", "iPad 3", "iPad 4", "iPad Air", "iPad Air 2", "iPad Mini", "iPad Mini 2", "iPad Mini 3", "iPad Mini 4", "iPad Pro 12.9":
            FrameExtractor.QUALITY = AVCaptureSessionPreset1920x1080
            FrameExtractor.MAX_WIDTH = CGFloat(1080)
            FrameExtractor.MAX_HEIGHT = CGFloat(1920)
            FrameExtractor.MAX_SCALE = 2
            scale = 2
            break;
        case "iPhone 6s", "iPhone 6s Plus", "iPhone 7", "iPhone 7 Plus", "iPhone SE", "iPad Pro 9.7":
            FrameExtractor.QUALITY = AVCaptureSessionPreset3840x2160
            FrameExtractor.MAX_WIDTH = CGFloat(2160)
            FrameExtractor.MAX_HEIGHT = CGFloat(3840)
            FrameExtractor.MAX_SCALE = 4
            scale = 4
            break;
        default :
            FrameExtractor.QUALITY = AVCaptureSessionPreset3840x2160
            FrameExtractor.MAX_WIDTH = CGFloat(2160)
            FrameExtractor.MAX_HEIGHT = CGFloat(3840)
            FrameExtractor.MAX_SCALE = 4
            scale = 4
            break;
        }
    }
    
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
        captureSession.sessionPreset = FrameExtractor.QUALITY
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
        connection.isVideoMirrored = FrameExtractor.POSITION == .front
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
    }
    
    private func applyFilter(ciImage: CIImage) -> CGImage {
        var cgImage: CGImage!
        
        switch filterList[filterStage] {
        case "none":
            cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
            break
        case "CIFalseColor0":
            let filter = CIFilter(name: "CIFalseColor")
            filter!.setValue(CIColor.blue(), forKey: "inputColor0")
            filter!.setValue(CIColor.yellow(), forKey: "inputColor1")
            filter!.setValue(ciImage, forKey: kCIInputImageKey)
            
            cgImage = context.createCGImage(filter!.value(forKey: kCIOutputImageKey) as! CIImage, from: ciImage.extent)!
            break
        case "CIFalseColor1":
            let filter = CIFilter(name: "CIFalseColor")
            filter!.setValue(CIColor.yellow(), forKey: "inputColor0")
            filter!.setValue(CIColor.blue(), forKey: "inputColor1")
            filter!.setValue(ciImage, forKey: kCIInputImageKey)
            
            cgImage = context.createCGImage(filter!.value(forKey: kCIOutputImageKey) as! CIImage, from: ciImage.extent)!
            break
        default:
            let filter = CIFilter(name: filterList[filterStage])
            filter!.setValue(ciImage, forKey: kCIInputImageKey)
            
            cgImage = context.createCGImage(filter!.value(forKey: kCIOutputImageKey) as! CIImage, from: ciImage.extent)!
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
        
        let cgImage = applyFilter(ciImage: ciImage)
        let cropedImage = cropImage(cgImage: cgImage)
        let uiImage = UIImage(cgImage: cropedImage)
        
        return uiImage
    }
    
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
        }    }
    
    func zoom() {
        if (scale > FrameExtractor.MIN_SCALE) {
            scale /= 2
        } else if (zoomFactor < FrameExtractor.MAX_ZOOM_FACTOR) {
            zoomFactor *= 2
        } else {
            zoomFactor = FrameExtractor.MIN_ZOOM_FACTOR
            scale = FrameExtractor.MAX_SCALE
        }
        
        do {
            try self.captureDevice?.lockForConfiguration()
            defer {self.captureDevice?.unlockForConfiguration()}
            
            self.captureDevice?.videoZoomFactor = CGFloat(zoomFactor)
        } catch {
            
        }
    }
}
