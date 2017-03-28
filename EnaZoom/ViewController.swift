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
    var photoHandler: PhotoHandler!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
        photoHandler = PhotoHandler()
        
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
        
        // view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned)))
    }
    
    func captured(image: UIImage) {
        imageView.image = image
    }
    
    func singleTapped() {
        photoHandler.saveScreenshot()
    }
    
    func doubleTapped() {
        frameExtractor.nextFilter()
    }
    
    func tripleTapped() {
        frameExtractor.toggleTorch()
    }
    
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

