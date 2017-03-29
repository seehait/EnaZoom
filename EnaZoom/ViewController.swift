//
//  ViewController.swift
//  EnaZoom
//
//  Created by Seehait Chockthanyawat on 3/28/17.
//  Copyright © 2017 Seehait Chockthanyawat. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FrameExtractorDelegate {
    @IBOutlet weak var imageView: UIImageView!

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
    
    @IBAction func topLeftTouched(_ sender: UIButton) {
        print("Top Left Touched")
        
        frameExtractor.toggleTorch()
    }
    
    @IBAction func topRightTouched(_ sender: UIButton) {
        print("Top Right Touched")
        
        frameExtractor.nextFilter()
    }
    
    @IBAction func bottomLeftTouched(_ sender: UIButton) {
        print("Bottom Left Touched")
        
        togglePause()
    }
    
    @IBAction func bottomRightTouched(_ sender: UIButton) {
        print("Bottom Right Touched")
        
        frameExtractor.zoom()
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

