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
    var selectedPrintIndex: Int?
    var resizerView: ResizerView!

    var showResizerGesture = UITapGestureRecognizer()
    var resizeGesture = UIPanGestureRecognizer()
    var isResizingMode = false

    var movePrintGesture = UIPanGestureRecognizer()
    var offSetPrint = CGPoint(x: 0, y: 0)
    var offSetResizer = CGPoint(x: 0, y: 0)
    
    let rotateAnimation = CABasicAnimation()
    var rotation: CGFloat = UserDefaults.standard.rotation
    var startRotationAngle: CGFloat = 0//0
    
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
        guard let index = self.selectedPrintIndex else {
            return
        }
        self.showResizerGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.showResizerGesture.numberOfTapsRequired = 1
        self.showResizerGesture.numberOfTouchesRequired = 1
        self.printImages[index].isUserInteractionEnabled = true
        self.showResizerGesture.delegate = self
        self.view.addGestureRecognizer(self.showResizerGesture)
    }
    
    func addResizeGesture() {
        guard let index = self.selectedPrintIndex else {
            return
        }
        self.resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(self.resizeImage(_:)))
        self.resizeGesture.delegate = self
        self.printImages[index].resizerView.addGestureRecognizer(self.resizeGesture)
    }
    
    func addMoveGesture() {
        guard let index = self.selectedPrintIndex else {
            return
        }
        self.movePrintGesture = UIPanGestureRecognizer(target: self, action: #selector(self.moveImage(_:)))
        self.movePrintGesture.maximumNumberOfTouches = 1
        self.movePrintGesture.minimumNumberOfTouches = 1
        self.movePrintGesture.delegate = self
        self.printImages[index].addGestureRecognizer(self.movePrintGesture)
    }
    
    func addRemoveGesture() {
        guard let index = self.selectedPrintIndex else {
            return
        }
        self.removePrintGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.deleteImage(_:)))
        self.removePrintGesture.delegate = self
        self.printImages[index].addGestureRecognizer(self.removePrintGesture)
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
            self.resizerView.hide()
        }
        printView.setConstraintsWithImage(sourceImage, areaFrame: self.areaView.frame)
        printView.tag = self.printImages.count
        self.selectedPrintIndex = printView.tag
        
        //rotation gesture carry out
        self.rotationGesture = UIRotationGestureRecognizer(target: self, action:     #selector(rotatedView(_:)))
        printView.addGestureRecognizer(self.rotationGesture)
        //
        guard let index = self.selectedPrintIndex else {
            return
        }
        self.printImages.append(printView)
        self.addShowResizerGesture()
        self.printImages[index].setupResizerView()
        self.resizerView = self.printImages[index].resizerView
        self.resizerView.show(with: self.printImages[index].frame)
        
//        let mask = CALayer()
//        mask.contents =  #imageLiteral(resourceName: "black").cgImage
//       // mask.backgroundColor = UIColor.clear.cgColor
//        mask.frame = self.areaView.frame
//        self.printImages[index].layer.mask = mask
//        self.printImages[index].layer.masksToBounds = true
//        self.printImages[index].contentMode = .scaleAspectFit
        
        self.addResizeGesture()
        self.addMoveGesture()
        self.addRemoveGesture()
    }
    
    func deletePrint(_ index: Int) {
        self.resizerView.removeFromSuperview()
        self.printImages[index].removeFromSuperview()
        self.printImages.remove(at: index)
        if self.printImages.isEmpty {
            for i in 0..<self.printImages.count {
                self.printImages[i].tag = i
            }
        }
    }
}
