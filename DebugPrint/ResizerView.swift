//
//  ResizerView.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 29/06/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import UIKit

class ResizerView: UIView, UIGestureRecognizerDelegate {

    var resizeGesture = UIPanGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = frame.width / 2
        self.backgroundColor = UIColor.green
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(with pictureFrame: CGRect) {
        self.frame.origin = CGPoint(x: pictureFrame.maxX - self.frame.width/2, y: pictureFrame.maxY - self.frame.width/2)
    }
    
    func show(with rect: CGRect) {
        self.isHidden = false
        self.isUserInteractionEnabled = true
        self.setup(with: rect)
    }
    
    func hide() {
        self.isHidden = true
        self.isUserInteractionEnabled = false
    }
}
