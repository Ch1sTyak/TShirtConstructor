//
//  AreaView.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 29/06/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import UIKit

class AreaView: UIImageView {
    
    private var horizontalConstraint = NSLayoutConstraint()
    private var verticalConstraint = NSLayoutConstraint()
    private var widthConstraint = NSLayoutConstraint()
    private var heightConstraint = NSLayoutConstraint()
    
    private var areaSize: PrintSize?

    convenience init(picture: UIImage) {
        self.init(frame: CGRect.zero)
        self.image = picture
    }
    
    func redrawArea(with format: PrintFormat) {
        self.areaSize?.format = format
        self.heightConstraint.constant = self.areaSize?.height ?? 0
        self.widthConstraint.constant = self.areaSize?.width ?? 0
        self.setNeedsLayout()
    }

    func setConstraints(with format: PrintFormat, tshirtFrame: CGRect) {
        guard let superView = self.superview else {
            print("No superview: forgot adding as subview")
            return
        }
        superView.removeConstraints([self.widthConstraint, self.heightConstraint, self.horizontalConstraint, self.verticalConstraint])
        
        self.areaSize = PrintSize(format: format, thsirtSize: tshirtFrame)

        self.translatesAutoresizingMaskIntoConstraints = false
        //center X constraint
        let horizontalConstraint1 = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 5)
        //center Y constraint
        let verticalConstraint1 = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint1 = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.areaSize?.width ?? 11)
        let heightConstraint1 = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.areaSize?.height ?? 11)
        
        superView.addConstraints([horizontalConstraint1, verticalConstraint1, widthConstraint1, heightConstraint1])
        
        self.heightConstraint = heightConstraint1
        self.widthConstraint = widthConstraint1
        self.horizontalConstraint = horizontalConstraint1
        self.verticalConstraint = verticalConstraint1
    }
}
