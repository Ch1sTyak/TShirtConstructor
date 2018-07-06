//
//  ViewController.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 26/06/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

//for dottedArea - need antother picture
let willEraseThisWidth: CGFloat = 36
let willEraseThisHeight: CGFloat = 44

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tshirtImageView: UIImageView!
    
    @IBOutlet weak var yellowChoiceButton: ColorButton!
    @IBOutlet weak var blueChoiceButton: ColorButton!
    
    @IBOutlet weak var a3SizeButton: FormatButton!
    @IBOutlet weak var a4SizeButton: FormatButton!
    @IBOutlet weak var a5SizeButton: FormatButton!
    
    @IBOutlet weak var loadButton: UIButton!
    
    var areaView: AreaView!    
    var printImages = [PrintView]()
    var selectedPrintIndex = 0
    var resizerView: ResizerView!

    var showResizerGesture = UITapGestureRecognizer()
    var resizeGesture = UIPanGestureRecognizer()
    var isResizingMode = false

    var movePrintGesture = UIPanGestureRecognizer()
    var offSetPrint = CGPoint(x: 0, y: 0)
    var offSetResizer = CGPoint(x: 0, y: 0)
    
    var rotationGesture = UIRotationGestureRecognizer()
    var lastRotation: CGFloat = 0
    var originalRotation: CGFloat = 0
    
    var removePrintGesture = UILongPressGestureRecognizer()
    
    override func loadView() {
        super.loadView()
        
        self.setupChoiceButtons(selectedButton: self.yellowChoiceButton)
        self.setupSizeButtons(selectedButton: self.a3SizeButton)
        self.areaView = AreaView(picture: #imageLiteral(resourceName: "DottedArea"))
        self.view.addSubview(self.areaView)
        self.areaView.setConstraints(with: .A3, tshirtFrame: self.tshirtImageView.frame)
        //
        
    }
    
    //MARK: - Views
    func setupChoiceButtons(selectedButton: ColorButton) {
        self.yellowChoiceButton.setDeselected()
        self.blueChoiceButton.setDeselected()
        selectedButton.setSelected()
    }
    
    func setupSizeButtons(selectedButton: FormatButton) {
        self.a3SizeButton.setDeselected()
        self.a4SizeButton.setDeselected()
        self.a5SizeButton.setDeselected()
        selectedButton.setSelected()
    }
    
    //MARK: - IBActions
    @IBAction func loadPrintAction(_ sender: Any) {
        self.showActionSheet()
    }
    
    @IBAction func yellowChoiceAction(_ sender: UIButton) {
        self.setupChoiceButtons(selectedButton: sender as! ColorButton)
        self.tshirtImageView.image = #imageLiteral(resourceName: "YellowTShirt")
    }
    
    @IBAction func blueChoiceAction(_ sender: UIButton) {
        self.setupChoiceButtons(selectedButton: sender as! ColorButton)
        self.tshirtImageView.image = #imageLiteral(resourceName: "BlueTShirt")
    }
    
    @IBAction func a3Action(_ sender: UIButton) {
        self.setupSizeButtons(selectedButton: sender as! FormatButton)
        self.areaView.redrawArea(with: .A3)
    }
    
    @IBAction func a4Action(_ sender: UIButton) {
        self.setupSizeButtons(selectedButton: sender as! FormatButton)
        self.areaView.redrawArea(with: .A4)
    }
    
    @IBAction func a5Action(_ sender: UIButton) {
        self.setupSizeButtons(selectedButton: sender as! FormatButton)
        self.areaView.redrawArea(with: .A5)
    }
    
    //MARK: - Gestures adding
    private func addShowResizerGesture() {
        self.showResizerGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.showResizerGesture.numberOfTapsRequired = 1
        self.showResizerGesture.numberOfTouchesRequired = 1
        self.printImages[selectedPrintIndex].isUserInteractionEnabled = true
        self.showResizerGesture.delegate = self
        self.view.addGestureRecognizer(self.showResizerGesture)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        for printView in self.printImages {
            let point = gesture.location(in: printView)
            if printView.point(inside: point, with: nil) {
                self.printImages[selectedPrintIndex].chooseResizerMode()
                self.selectedPrintIndex = printView.tag
                if self.selectedPrintIndex != printView.tag {
                    self.selectedPrintIndex = printView.tag
                    self.printImages[selectedPrintIndex].chooseResizerMode()
                }
                self.view.bringSubview(toFront: self.printImages[selectedPrintIndex])
                self.resizerView = self.printImages[selectedPrintIndex].resizerView
                self.view.bringSubview(toFront: self.resizerView)
                return
            }
        }
    }
    
    func addResizeGesture() {
        self.resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(self.resizeImage(_:)))
        self.resizeGesture.delegate = self
        self.printImages[selectedPrintIndex].resizerView.addGestureRecognizer(self.resizeGesture)
    }
    
    func addMoveGesture() {
        self.movePrintGesture = UIPanGestureRecognizer(target: self, action: #selector(self.moveImage(_:)))
        self.movePrintGesture.delegate = self
        self.printImages[selectedPrintIndex].addGestureRecognizer(self.movePrintGesture)
    }
    
    func addRemoveGesture() {
        self.removePrintGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.deleteImage(_:)))
        self.removePrintGesture.delegate = self
        self.printImages[selectedPrintIndex].addGestureRecognizer(self.removePrintGesture)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.addPrint(with: pickedImage)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Functions
    private func addPhoto(withType: UIImagePickerControllerSourceType) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if authStatus == AVAuthorizationStatus.denied {
            var actions = [UIAlertAction]()
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            actions.append(okAction)
            let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        // Finished opening URL
                    })
                }
            })
            actions.append(settingsAction)
            self.showAlert("Unable to access the Camera", "To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app.", actions)
        }
        else if (authStatus == AVAuthorizationStatus.notDetermined) {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        let imagePicker = UIImagePickerController()
                        imagePicker.delegate = self
                        imagePicker.sourceType = withType
                        imagePicker.mediaTypes = [kUTTypeImage] as [String]
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
            })
        } else {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = withType
            imagePicker.mediaTypes = [kUTTypeImage] as [String]
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func showActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let chooseAction = UIAlertAction(title: "Выбрать фото из библиотеки", style: .default) { [weak self](action) in
            //gallery
            self?.addPhoto(withType: .photoLibrary)
        }
        let photoAction = UIAlertAction(title: "Сделать фото", style: .default) { [weak self](action) in
            //camera
            self?.addPhoto(withType: .camera)
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { (action) in }
        alert.addAction(chooseAction)
        alert.addAction(photoAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = self.loadButton
        self.present(alert, animated: true, completion: nil)
    }
    
    func addPrint(with sourceImage: UIImage) {
        let printView = PrintView(frame: CGRect.zero)
        self.view.addSubview(printView)
        
        self.view.bringSubview(toFront: printView)
        
        if !self.printImages.isEmpty {
            self.printImages[selectedPrintIndex].chooseResizerMode()
        }
        
        printView.setConstraintsWithImage(sourceImage, areaFrame: self.areaView.frame)
        printView.tag = self.printImages.count
        self.selectedPrintIndex = printView.tag
        
//        self.rotationGesture = UIRotationGestureRecognizer(target: self, action:     #selector(rotatedView(_:)))
//        printView.addGestureRecognizer(self.rotationGesture)
        
        self.printImages.append(printView)
        self.addShowResizerGesture()
        self.printImages[selectedPrintIndex].setupResizerView()
        self.resizerView = self.printImages[selectedPrintIndex].resizerView
        self.addResizeGesture()
        self.addMoveGesture()
        self.addRemoveGesture()
    }
    
    fileprivate let rotateAnimation = CABasicAnimation()
    fileprivate var rotation: CGFloat = UserDefaults.standard.rotation
    fileprivate var startRotationAngle: CGFloat = 0//0

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
    
}

extension ViewController {
    //MARK: - Gesture actions
    @objc func rotatedView(_ gesture: UIRotationGestureRecognizer) {
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
    
    @objc func resizeImage(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        
            /*      if abs(translation.y - translation.x) < 25 {//3.2 {
             self.resizerView.center = CGPoint(x: self.printImages[self.selectedPrint].frame.maxX + translation.x, y: self.printImages[0].frame.maxY + translation.y)
             self.resizerView.center = CGPoint(x: self.printImages[self.selectedPrint].frame.maxX + translation.x, y: self.printImages[self.selectedPrint].frame.maxY + translation.y)
             if gesture.state == .changed  || gesture.state == .began {
             self.printImages[self.selectedPrint].widthConstraint.constant += translation.x * 2//max(translation.x, translation.y) * 2
             gesture.setTranslation(CGPoint.zero, in: self.view)
             } else if gesture.state == .ended || gesture.state == .cancelled {
             
             }
             }
             }   else {*/
            
            //rotation
            let location = gesture.location(in: self.view)
            let gestureRotation = CGFloat(angle(from: location)) - startRotationAngle
            self.moveTraceResizer(gestureRotation: gestureRotation)
            
            switch gesture.state {
            case .began:
                startRotationAngle = angle(from: location)
                self.rotate(to: rotation - gestureRotation.degreesToRadians, view: self.printImages[self.selectedPrintIndex])
                gesture.setTranslation(CGPoint.zero, in: self.view)
            case .changed:
                self.rotate(to: rotation - gestureRotation.degreesToRadians, view: self.printImages[self.selectedPrintIndex])
                gesture.setTranslation(CGPoint.zero, in: self.view)
            case .ended:
                rotation -= gestureRotation.degreesToRadians
            default:
                break
            }
            UserDefaults.standard.rotation = rotation
    }
    
    func angle(from location: CGPoint) -> CGFloat {
        let deltaY = location.y - self.printImages[self.selectedPrintIndex].center.y//view.center.y
        let deltaX = location.x - self.printImages[self.selectedPrintIndex].center.x//view.center.x
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        //print(angle)
        return angle < 0 ? abs(angle) : 360 - angle
    }
    //change center?
    func angleResizer(from location: CGPoint) -> CGFloat {
        let deltaY = self.resizerView.center.y -  location.y //view.center.y
        let deltaX = self.resizerView.center.x - location.x//view.center.x
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        //print(angle)
        return angle < 0 ? abs(angle) : 360 - angle
    }
    
    @objc func moveImage(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        switch (gesture.state) {
        case .began:
            self.offSetPrint = CGPoint(x: self.printImages[self.selectedPrintIndex].horizontalConstraint.constant, y:  self.printImages[self.selectedPrintIndex].verticalConstraint.constant)
            self.offSetResizer = CGPoint(x: self.resizerView.frame.origin.x, y:  self.resizerView.frame.origin.y)
        case .changed:
            self.printImages[self.selectedPrintIndex].horizontalConstraint.constant = offSetPrint.x + translation.x
            self.printImages[self.selectedPrintIndex].verticalConstraint.constant = offSetPrint.y + translation.y
            self.printImages[self.selectedPrintIndex].resizerView.frame.origin = CGPoint(x: offSetResizer.x + translation.x, y: offSetResizer.y + translation.y)
        default:
            break
        }
    }
    
    @objc func deleteImage(_ gesture: UILongPressGestureRecognizer) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let location = gesture.location(in: gesture.view)
        var selectedPrint: PrintView?
        for printView in self.printImages {
            if printView.point(inside: location, with: nil) {
                selectedPrint = printView
            }
        }
        guard let printForRemove = selectedPrint else {
            return
        }
        actionSheet.popoverPresentationController?.sourceView = printForRemove
        let removeAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] (_) in
            printForRemove.resizerView.removeFromSuperview()
            printForRemove.removeFromSuperview()
            self?.printImages.remove(at: printForRemove.tag)
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        actionSheet.addAction(removeAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
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
        self.resizerView.center = CGPoint(x: self.printImages[self.selectedPrintIndex].center.x + self.printImages[self.selectedPrintIndex].frame.width/2  * (rotation.degreesToRadians - gestureRotation.degreesToRadians), y: self.printImages[self.selectedPrintIndex].center.y + self.printImages[self.selectedPrintIndex].frame.height/2 * (rotation.degreesToRadians - gestureRotation.degreesToRadians))
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension UserDefaults {
    var rotation: CGFloat {
        get {
            return CGFloat(double(forKey: "rotation"))
        }
        set {
            set(Double(newValue), forKey: "rotation")
        }
    }
}
