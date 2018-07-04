//
//  FormatButton.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 29/06/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import UIKit

class FormatButton: UIButton {
    
    private var side: Double = 30.0
    var isSelectedButton = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.side = Double(frame.width)
        self.layer.cornerRadius = CGFloat((self.side / 2) - (self.side / 10))
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.layer.cornerRadius = CGFloat((side / 2) - (side / 10))
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
    }
    
    func setDeselected() {
        self.layer.cornerRadius = CGFloat((side / 2) - (side / 10))
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
    }
    
    func setSelected() {
        self.layer.cornerRadius = CGFloat((side / 2) - (side / 10))
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.orange.cgColor
    }
}
