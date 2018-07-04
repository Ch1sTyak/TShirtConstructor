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
    
    //MARK: - ShowResizer gesture
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
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if !self.printImages.isEmpty {
                self.printImages[0].removeFromSuperview()
            }
            self.printImages.removeAll()
            let printView = PrintView(frame: CGRect.zero)
            self.view.addSubview(printView)
            printView.setConstraintsWithImage(pickedImage, areaFrame: self.areaView.frame)
            self.printImages.append(printView)
            self.addShowResizerGesture()
            self.printImages[0].setupResizerView()
            self.addResizeGesture()
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
}

//extension ViewController: UIGestureRecognizerDelegate {
//    //вычисляется угол для определения направления жеста
//    //угол для свайпа справа налево: от 7пи/8 до пи (по модулю)
//    //если бы нам нужен свайп слева направо: наш угол - до 0 (погрешность определяем по желанию)
////    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
////        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
////            let translation = pan.translation(in: pan.view)
////            let angleFromTouch = abs(atan2(translation.x, translation.y))
////            if self.printImageView == nil {
////                return false
////            }
////            let angleFromImage = abs(atan2(self.printImageView.frame.width, self.printImageView.frame.height))
////            //return angle < .pi / 8.0
////
////            if angleFromTouch < angleFromImage {
////                print("case reached")
////            }
////            return angleFromTouch >= angleFromImage
////        }
////        return false
////    }
//    
//    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        if gestureRecognizer.view?.isKind(of: PrintView.self) ?? false {
//            print("touch reached")
//        }
//        return true
//    }
//    
    //CARRY OUT TO PrintView gesture recognizer
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print(touches)
//        if touches.count == 1 {
////            guard let location = touches.first?.location(in: self.view) else {
////                return
////            }
////            if self.printImages.isEmpty {
////                return
////            }
////            let printImageViewFrame = self.view.convert(self.view.frame, from: self.printImages[0])
////            let resizerViewFrame = self.view.convert(self.view.frame, from: self.resizerView)
////            if printImageViewFrame.contains(location) && self.resizerView == nil {
////                self.setupResizerViewWithPanGesture()
////            } else {
////                if self.resizerView != nil && !resizerViewFrame.contains(location) {
////                    self.resizerView.removeFromSuperview()
////                    self.resizerView = nil
////                }
////            }
//        }
//    }
//}

extension ViewController {
    //MARK: - Gesture actions
    @objc func resizeImage(_ gesture: UIPanGestureRecognizer) {
        print("RESIZE IMAGE")
        if gesture.state == .began {
//            UIView.animate(withDuration: 0.6) { [weak self] in
//                self?.printImages[0].resizerView.backgroundColor = UIColor.red
//            }
            let translationView = gesture.translation(in: self.view)
            
            self.printImages[0].widthConstraint.constant += translationView.x * 2
            
            let translation = gesture.translation(in: self.view)
            self.printImages[0].resizerView.center = CGPoint(x: self.printImages[0].resizerView.center.x + translation.x, y: self.printImages[0].resizerView.center.y + translation.y)
            gesture.setTranslation(CGPoint.zero, in: self.view)
        } else if gesture.state == .changed  || gesture.state == .began {
            let translationView = gesture.translation(in: self.view)
        
            self.printImages[0].widthConstraint.constant += translationView.x * 2
            
            let translation = gesture.translation(in: self.view)
            self.printImages[0].resizerView.center = CGPoint(x: self.printImages[0].resizerView.center.x + translation.x, y: self.printImages[0].resizerView.center.y + translation.y)
            gesture.setTranslation(CGPoint.zero, in: self.view)
        } else if gesture.state == .ended || gesture.state == .cancelled {
//            UIView.animate(withDuration: 0.6) { [weak self] in
//                self?.printImages[0].resizerView.backgroundColor = UIColor.green
//            }
        }
    }
}


//self.printImages[0].widthConstraint.constant = (1 / self.printImages[0].aspectRatioConstraint.multiplier) * self.printImages[0].heightConstraint.constant

