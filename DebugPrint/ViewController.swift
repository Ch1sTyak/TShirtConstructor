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
    var resizerView: UIView!

    var showResizerGesture = UITapGestureRecognizer()
    var resizeGesture = UIPanGestureRecognizer()
    var isResizingMode = false

    var movePrintGesture = UIPanGestureRecognizer()
    var offSetPrint = CGPoint(x: 0, y: 0)
    var offSetResizer = CGPoint(x: 0, y: 0)

    override func loadView() {
        super.loadView()
        
        self.setupChoiceButtons(selectedButton: self.yellowChoiceButton)
        self.setupSizeButtons(selectedButton: self.a3SizeButton)
        self.areaView = AreaView(picture: #imageLiteral(resourceName: "DottedArea"))
        self.view.addSubview(self.areaView)
        self.areaView.setConstraints(with: .A3, tshirtFrame: self.tshirtImageView.frame)
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
        self.printImages[0].isUserInteractionEnabled = true
        self.showResizerGesture.delegate = self
        self.view.addGestureRecognizer(self.showResizerGesture)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        self.printImages[0].chooseResizerMode()
    }
    
    func addResizeGesture() {
        self.resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(self.resizeImage(_:)))
        self.resizeGesture.delegate = self
        self.printImages[0].resizerView.addGestureRecognizer(self.resizeGesture)
    }
    
    func addMoveGesture() {
        self.movePrintGesture = UIPanGestureRecognizer(target: self, action: #selector(self.moveImage(_:)))
        self.movePrintGesture.delegate = self
        self.printImages[0].addGestureRecognizer(self.movePrintGesture)
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
        if !self.printImages.isEmpty {
            self.printImages[0].resizerView.removeFromSuperview()
            self.printImages[0].removeFromSuperview()
        }
        self.printImages.removeAll()
        let printView = PrintView(frame: CGRect.zero)
        self.view.addSubview(printView)
        printView.setConstraintsWithImage(sourceImage, areaFrame: self.areaView.frame)
        self.printImages.append(printView)
        self.addShowResizerGesture()
        self.printImages[0].setupResizerView()
        self.addResizeGesture()
        self.addMoveGesture()
    }
    
    fileprivate let rotateAnimation = CABasicAnimation()
    fileprivate var rotation: CGFloat = UserDefaults.standard.rotation
    fileprivate var startRotationAngle: CGFloat = 0
    
    func rotate(to: CGFloat, duration: Double = 0) {
        rotateAnimation.fromValue = to
        rotateAnimation.toValue = to
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = 0
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.fillMode = kCAFillModeForwards
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.printImages[0].layer.add(rotateAnimation, forKey: "transform.rotation.z")
    }
}

extension ViewController {
    //MARK: - Gesture actions
    @objc func resizeImage(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        
        /*if abs(translation.y - translation.x) < 3.2 {
            self.printImages[0].resizerView.center = CGPoint(x: self.printImages[0].frame.maxX + translation.x, y: self.printImages[0].frame.maxY + translation.y)
            self.printImages[0].resizerView.center = CGPoint(x: self.printImages[0].frame.maxX + translation.x, y: self.printImages[0].frame.maxY + translation.y)
            if gesture.state == .changed  || gesture.state == .began {
                self.printImages[0].widthConstraint.constant += translation.x * 2//max(translation.x, translation.y) * 2
                gesture.setTranslation(CGPoint.zero, in: self.view)
            } else if gesture.state == .ended || gesture.state == .cancelled {
                
            }
        } else {*/
            self.printImages[0].resizerView.center = CGPoint(x: self.printImages[0].frame.minX + self.printImages[0].bounds.width + translation.x, y: self.printImages[0].frame.minY + self.printImages[0].bounds.height + translation.y)
            //rotation
            let location = gesture.location(in: self.view)
            let gestureRotation = CGFloat(angle(from: location)) - startRotationAngle
            switch gesture.state {
            case .began:
                //write starting angle?
                startRotationAngle = angle(from: location)
                self.rotate(to: rotation - gestureRotation.degreesToRadians)
                //rotate image
                gesture.setTranslation(CGPoint.zero, in: self.view)            case .changed:
                //let translation = gesture.translation(in: self.view)
                self.rotate(to: rotation - gestureRotation.degreesToRadians)
                //rotate image
                gesture.setTranslation(CGPoint.zero, in: self.view)
            case .ended:
                // update the amount of rotation
                rotation -= gestureRotation.degreesToRadians
            default:
                break
            }
            UserDefaults.standard.rotation = rotation
       // }
    }
    
    func angle(from location: CGPoint) -> CGFloat {
        let deltaY = location.y - view.center.y
        let deltaX = location.x - view.center.x
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        return angle < 0 ? abs(angle) : 360 - angle
    }
    
    @objc func moveImage(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        switch (gesture.state) {
        case .began:
            self.offSetPrint = CGPoint(x: self.printImages[0].horizontalConstraint.constant, y:  self.printImages[0].verticalConstraint.constant)
            self.offSetResizer = CGPoint(x: self.printImages[0].resizerView.frame.origin.x, y:  self.printImages[0].resizerView.frame.origin.y)
        case .changed:
            self.printImages[0].horizontalConstraint.constant = offSetPrint.x + translation.x
            self.printImages[0].verticalConstraint.constant = offSetPrint.y + translation.y
            self.printImages[0].resizerView.frame.origin = CGPoint(x: offSetResizer.x + translation.x, y: offSetResizer.y + translation.y)
        default:
            break
        }
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
