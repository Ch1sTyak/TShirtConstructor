//
//  Extensions.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 27/06/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(_ withText: String, _ andDescription: String?, _ actions: [UIAlertAction]? = nil) {
        let alert = UIAlertController(title: withText, message: andDescription, preferredStyle: .alert)
        if let unwrappedActions = actions, !unwrappedActions.isEmpty {
            for action in unwrappedActions {
                alert.addAction(action)
            }
        } else {
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: { (action) -> Void in
            })
            alert.addAction(cancelAction)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func flashAlert(_ withText: String, _ andDescription: String?, withDelay: Double) {
        let alert = UIAlertController(title: withText, message: andDescription, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + withDelay) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func flashAlert(_ withText: String, _ andDescription: String?, withDelay: Double, completion: @escaping(()->())) {
        let alert = UIAlertController(title: withText, message: andDescription, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + withDelay) {
            alert.dismiss(animated: true, completion: nil)
            completion()
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

extension UIGestureRecognizer {
    func detectSelectedPrint(among printImages: [PrintView]) -> Int? {
        for printView in printImages {
            let point = self.location(in: printView)
            if printView.point(inside: point, with: nil) {
                return printView.tag
            }
        }
        return nil
    }
}
