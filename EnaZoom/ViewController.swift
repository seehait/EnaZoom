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
    
    var frameExtractor: FrameExtractor!
    // var photoHandler: PhotoHandler!
    
    var isPause = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
        // photoHandler = PhotoHandler()
        /*
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        singleTap.numberOfTapsRequired = 1
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(tripleTapped))
        tripleTap.numberOfTapsRequired = 3
        
        singleTap.require(toFail: doubleTap)
        singleTap.require(toFail: tripleTap)
        doubleTap.require(toFail: tripleTap)
        
        view.addGestureRecognizer(singleTap)
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(tripleTap)
        */
        // view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned)))
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
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            guideBox.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        } else {
            guideBox.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        }
                
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
        if sender.state == UIGestureRecognizerState.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.ZOOM_TEXT, color: ViewController.ZOOM_COLOR)
            } else {
                showGuideBox(text: ViewController.TORCH_TEXT, color: ViewController.TORCH_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizerState.ended {
            hideGuideBox()
        }
    }
    
    @IBAction func topRightLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.HOLD_TEXT, color: ViewController.HOLD_COLOR)
            } else {
                showGuideBox(text: ViewController.FILTER_TEXT, color: ViewController.FILTER_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizerState.ended {
            hideGuideBox()
        }
    }
    
    @IBAction func bottomLeftLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.FILTER_TEXT, color: ViewController.FILTER_COLOR)
            } else {
                showGuideBox(text: ViewController.HOLD_TEXT, color: ViewController.HOLD_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizerState.ended {
            hideGuideBox()
        }
    }
    
    @IBAction func bottomRightLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                showGuideBox(text: ViewController.TORCH_TEXT, color: ViewController.TORCH_COLOR)
            } else {
                showGuideBox(text: ViewController.ZOOM_TEXT, color: ViewController.ZOOM_COLOR)
            }
        }
        else if sender.state == UIGestureRecognizerState.ended {
            hideGuideBox()
        }
    }
    
    /*
    func singleTapped() {
        frameExtractor.zoom()
    }
    
    func doubleTapped() {
        frameExtractor.nextFilter()
    }
    
    func tripleTapped() {
        frameExtractor.toggleTorch()
    }
    */
    
    /*
     func panned(gesture: UIPanGestureRecognizer) {
     frameExtractor.saveImage()
     
     
     let translation = gesture.translation(in: view)
     if (translation.y < 0) {
     
     } else if (translation.y > 0) {
     frameExtractor.prevFilter()
     }
     }
     */
}

