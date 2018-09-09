//
//  ViewController.swift
//  EnaZoom
//
//  Created by Seehait Chockthanyawat on 3/28/17.
//  Copyright © 2017 Seehait Chockthanyawat. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FrameExtractorDelegate {
    static let ZOOM_TEXT = "Zoom In"
    static let HOLD_TEXT = "Hold"
    static let FILTER_TEXT = "Change Filter"
    static let TORCH_TEXT = "Toggle Torch"
    
    static let ZOOM_COLOR = UIColor(red: 178/255.0, green: 2/255.0, blue: 0/255.0, alpha: 1)
    static let HOLD_COLOR = UIColor(red: 0/255.0, green: 178/255.0, blue: 56/255.0, alpha: 1)
    static let FILTER_COLOR = UIColor(red: 0/255.0, green: 21/255.0, blue: 255/255.0, alpha: 1)
    static let TORCH_COLOR = UIColor(red: 255/255.0, green: 199/255.0, blue: 0/255.0, alpha: 1)
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var guideBox: UILabel!
    
    @IBOutlet weak var topLeftBorder: UIView!
    @IBOutlet weak var topRightBorder: UIView!
    @IBOutlet weak var leftTopBorder: UIView!
    @IBOutlet weak var rightTopBorder: UIView!
    @IBOutlet weak var leftBottomBorder: UIView!
    @IBOutlet weak var rightBottomBorder: UIView!
    @IBOutlet weak var bottomLeftBorder: UIView!
    @IBOutlet weak var bottomRightBorder: UIView!
    
    var frameExtractor: FrameExtractor!
    var photoHandler: PhotoHandler!
    
    var isPause = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        photoHandler = PhotoHandler()
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    @objc func deviceOrientationDidChange() {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            guideBox.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            
            topLeftBorder.backgroundColor = ViewController.ZOOM_COLOR
            topRightBorder.backgroundColor = ViewController.HOLD_COLOR
            leftTopBorder.backgroundColor = ViewController.ZOOM_COLOR
            rightTopBorder.backgroundColor = ViewController.HOLD_COLOR
            leftBottomBorder.backgroundColor = ViewController.FILTER_COLOR
            rightBottomBorder.backgroundColor = ViewController.TORCH_COLOR
            bottomLeftBorder.backgroundColor = ViewController.FILTER_COLOR
            bottomRightBorder.backgroundColor = ViewController.TORCH_COLOR
        } else {
            guideBox.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            
            topLeftBorder.backgroundColor = ViewController.TORCH_COLOR
            topRightBorder.backgroundColor = ViewController.FILTER_COLOR
            leftTopBorder.backgroundColor = ViewController.TORCH_COLOR
            rightTopBorder.backgroundColor = ViewController.FILTER_COLOR
            leftBottomBorder.backgroundColor = ViewController.HOLD_COLOR
            rightBottomBorder.backgroundColor = ViewController.ZOOM_COLOR
            bottomLeftBorder.backgroundColor = ViewController.HOLD_COLOR
            bottomRightBorder.backgroundColor = ViewController.ZOOM_COLOR
        }
    }
    
    func captured(image: UIImage) {
        if (isPause) {
            
        } else {
            imageView.image = image
        }
    }
    
    private func togglePause() {
        isPause = !isPause
    }
    
    private func showGuideBox(text: String, color: UIColor) {
        guideBox.text = text
        guideBox.backgroundColor = color
    }
    
    private func hideGuideBox() {
        guideBox.text = ""
        guideBox.backgroundColor = UIColor.black.withAlphaComponent(0)
    }
    
    @IBAction func topLeftTouched(_ sender: UIButton) {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            frameExtractor.zoom()
        } else {
            frameExtractor.toggleTorch()
        }
    }
    
    @IBAction func topRightTouched(_ sender: UIButton) {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            togglePause()
        } else {
            frameExtractor.nextFilter()
        }
    }
    
    @IBAction func bottomLeftTouched(_ sender: UIButton) {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            frameExtractor.nextFilter()
        } else {
            togglePause()
        }
    }
    
    @IBAction func bottomRightTouched(_ sender: UIButton) {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            frameExtractor.toggleTorch()
        } else {
            frameExtractor.zoom()
        }
    }
    
    @IBAction func topLeftLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.ZOOM_TEXT, color: ViewController.ZOOM_COLOR)
            } else {
                showGuideBox(text: ViewController.TORCH_TEXT, color: ViewController.TORCH_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizer.State.ended {
            hideGuideBox()
        }
    }
    
    @IBAction func topRightLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.HOLD_TEXT, color: ViewController.HOLD_COLOR)
            } else {
                showGuideBox(text: ViewController.FILTER_TEXT, color: ViewController.FILTER_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizer.State.ended {
            hideGuideBox()
        }
    }
    
    @IBAction func bottomLeftLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.FILTER_TEXT, color: ViewController.FILTER_COLOR)
            } else {
                showGuideBox(text: ViewController.HOLD_TEXT, color: ViewController.HOLD_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizer.State.ended {
            hideGuideBox()
        }
    }
    
    @IBAction func bottomRightLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.TORCH_TEXT, color: ViewController.TORCH_COLOR)
            } else {
                showGuideBox(text: ViewController.ZOOM_TEXT, color: ViewController.ZOOM_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizer.State.ended {
            hideGuideBox()
        }
    }
    
    @objc func doubleTapped() {
        photoHandler.save(image: imageView!.image!)
    }
}
