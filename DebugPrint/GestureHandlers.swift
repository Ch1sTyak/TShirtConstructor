//
//  GestureHandlers.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 06/07/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import UIKit

extension ViewController {
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        if let _ = self.selectedPrintIndex  {
            self.resizerView.hide()
        }
        guard let index = gesture.detectSelectedPrint(among: self.printImages) else {
            return
        }
        self.selectedPrintIndex = index
        self.resizerView = self.printImages[index].resizerView
        self.resizerView.show(with: self.printImages[index].frame)
    }
    
    @objc func rotatedView(_ gesture: UIRotationGestureRecognizer) {
        guard let index = gesture.detectSelectedPrint(among: self.printImages) else {
            return
        }
        self.selectedPrintIndex = index
        switch gesture.state {
        case .began:
            gesture.rotation = self.lastRotation
            self.originalRotation = gesture.rotation
        case .changed:
            let newRotation = gesture.rotation + self.originalRotation
            gesture.view?.transform = CGAffineTransform(rotationAngle: newRotation)
        case .ended, .cancelled:
            self.lastRotation = gesture.rotation
        default:
            break
        }
    }
    
    func rotate(to: CGFloat, duration: Double = 0, view: UIView) {
        rotateAnimation.fromValue = to //- 26
        rotateAnimation.toValue = to //- 26
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = 0
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.fillMode = kCAFillModeForwards
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        view.layer.add(rotateAnimation, forKey: "transform.rotation.z")
    }
    
    func angle(from location: CGPoint) -> CGFloat {
        guard let index = self.selectedPrintIndex else {
            return 0
        }
        let deltaY = location.y - self.printImages[index].center.y//view.center.y
        let deltaX = location.x - self.printImages[index].center.x//view.center.x
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        //print(angle)
        return angle < 0 ? abs(angle) : 360 - angle
    }
    
    
    func moveTraceResizer(gestureRotation: CGFloat) {
        //        switch rotation.degreesToRadians - gestureRotation.degreesToRadians {
        //        case 0..< (.pi / 2) :
        //            print("asd")
        //        case .pi/2..<.pi:
        //            print("asd")
        //        case .pi..<.3*pi/2:
        //        case .pi/2..<.pi:
        //
        //        }
        guard let index = self.selectedPrintIndex else {
            return
        }
        self.resizerView.center = CGPoint(x: self.printImages[index].center.x + self.printImages[index].frame.width/2  * (rotation.degreesToRadians - gestureRotation.degreesToRadians), y: self.printImages[index].center.y + self.printImages[index].frame.height/2 * (rotation.degreesToRadians - gestureRotation.degreesToRadians))
        //self.resizerView.center = self.resizerView.layer.convert(CGPoint(x: self.printImages[index].frame.maxX, y: self.printImages[index].frame.maxY), to: self.printImages[index].layer)
    }
    
    @objc func resizeImage(_ gesture: UIPanGestureRecognizer) {
        guard let index = self.selectedPrintIndex else {//gesture.detectSelectedPrint(among: self.printImages) else {
            return
        }
        // self.selectedPrintIndex = index
        
        let translation = gesture.translation(in: self.view)
        
        if abs(translation.y - translation.x) < 25 {//3.2 {
            self.resizerView.center = CGPoint(x: self.printImages[index].frame.maxX + translation.x, y: self.printImages[0].frame.maxY + translation.y)
            self.resizerView.center = CGPoint(x: self.printImages[index].frame.maxX + translation.x, y: self.printImages[index].frame.maxY + translation.y)
            if gesture.state == .changed  || gesture.state == .began {
                self.printImages[index].widthConstraint.constant += translation.x * 2//max(translation.x, translation.y) * 2
                gesture.setTranslation(CGPoint.zero, in: self.view)
            } else if gesture.state == .ended || gesture.state == .cancelled {
                
            }
        } /*  else {
        
        //rotation
        let location = gesture.location(in: self.view)
        let gestureRotation = CGFloat(angle(from: location)) - startRotationAngle
        self.moveTraceResizer(gestureRotation: gestureRotation)
        
        switch gesture.state {
        case .began:
            startRotationAngle = angle(from: location)
            self.rotate(to: rotation - gestureRotation.degreesToRadians, view: self.printImages[index])
            gesture.setTranslation(CGPoint.zero, in: self.view)
        case .changed:
            self.rotate(to: rotation - gestureRotation.degreesToRadians, view: self.printImages[index])
            gesture.setTranslation(CGPoint.zero, in: self.view)
        case .ended:
            rotation -= gestureRotation.degreesToRadians
        default:
            break
        }
        UserDefaults.standard.rotation = rotation*/
    }
    
    @objc func moveImage(_ gesture: UIPanGestureRecognizer) {
        if self.resizerView != nil {
            self.resizerView.hide()
        }
        guard let index = gesture.detectSelectedPrint(among: self.printImages) else {
            return
        }
        self.selectedPrintIndex = index
        self.resizerView = self.printImages[index].resizerView
        self.resizerView.show(with: self.printImages[index].frame)
        let translation = gesture.translation(in: self.view)
        switch (gesture.state) {
        case .began:
            self.offSetPrint = CGPoint(x: self.printImages[index].horizontalConstraint.constant, y:  self.printImages[index].verticalConstraint.constant)
            self.offSetResizer = CGPoint(x: self.resizerView.frame.origin.x, y:  self.resizerView.frame.origin.y)
        case .changed:
            self.printImages[index].horizontalConstraint.constant = offSetPrint.x + translation.x
            self.printImages[index].verticalConstraint.constant = offSetPrint.y + translation.y
            self.printImages[index].resizerView.frame.origin = CGPoint(x: offSetResizer.x + translation.x, y: offSetResizer.y + translation.y)
        default:
            break
        }
    }
    
    @objc func deleteImage(_ gesture: UILongPressGestureRecognizer) {
        guard let index = gesture.detectSelectedPrint(among: self.printImages) else {
            return
        }
        self.selectedPrintIndex = index
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.popoverPresentationController?.sourceView = self.printImages[index]
        let removeAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] (_) in
            self?.deletePrint(index)
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        actionSheet.addAction(removeAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
}
