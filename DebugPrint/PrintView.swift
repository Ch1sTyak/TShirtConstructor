//
//  PrintView.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 29/06/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import UIKit

class PrintView: UIImageView, UIGestureRecognizerDelegate {
    
     var horizontalConstraint = NSLayoutConstraint()
     var verticalConstraint = NSLayoutConstraint()
     var widthConstraint = NSLayoutConstraint()
     var heightConstraint = NSLayoutConstraint()
     var aspectRatioConstraint = NSLayoutConstraint()
    
    private var showResizerGesture = UITapGestureRecognizer()
    private var dragPrintGesture = UIPanGestureRecognizer()
    
    var resizerView: ResizerView!
    private var isResizingMode = false
    
    func setConstraintsWithImage(_ sourceImage: UIImage, areaFrame: CGRect) {//(size: CGSize) {
        guard let superView = self.superview else {
            print("No superview: forgot adding as subview")
            return
        }
        
        let size = sourceImage.size
        let aspectRatio = size.height / size.width
        self.clipsToBounds = true
        
        superView.addSubview(self) //areaView
        self.translatesAutoresizingMaskIntoConstraints = false
        
        //center X constraint
        let horizontalConstraint1 = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: superView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 5)
        //center Y constraint
        let verticalConstraint1 = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: superView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        
        let widthConstant = size.height > size.width ? (areaFrame.height - willEraseThisHeight) / aspectRatio : areaFrame.width - willEraseThisWidth
        let heightConstant = size.height > size.width ? areaFrame.height - willEraseThisHeight : (areaFrame.width - willEraseThisWidth) * aspectRatio
        
        let widthConstraint1 = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: widthConstant)
        let heightConstraint1 = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: heightConstant)
        
        let ratioConstraint = NSLayoutConstraint(item: self,
                                                 attribute: NSLayoutAttribute.height,
                                                 relatedBy: NSLayoutRelation.equal,
                                                 toItem: self,
                                                 attribute: NSLayoutAttribute.width,
                                                 multiplier: aspectRatio,
                                                 constant: 1)
        
        superView.addConstraints([horizontalConstraint1, verticalConstraint1, widthConstraint1, /*heightConstraint1,*/ ratioConstraint])
        
        self.widthConstraint = widthConstraint1
        self.heightConstraint = heightConstraint1
        self.aspectRatioConstraint = ratioConstraint
        self.horizontalConstraint = horizontalConstraint1
        self.verticalConstraint = verticalConstraint1
        
        self.image = sourceImage
    }
    
    func setupResizerView() {
        self.resizerView = ResizerView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        self.superview?.addSubview(self.resizerView)
        self.resizerView.setup(with: self.frame)
        self.resizerView.hide()
    }
    
    func chooseResizerMode() {
        if self.isResizingMode {
            self.resizerView.hide()
            self.isResizingMode = false
        } else {
            self.resizerView.show(with: self.frame)
            self.isResizingMode = true
        }
    }
}
