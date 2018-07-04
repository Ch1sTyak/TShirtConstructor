//
//  Sizes.swift
//  DebugPrint
//
//  Created by Michael Nechaev on 27/06/2018.
//  Copyright © 2018 Michael Nechaev. All rights reserved.
//

import Foundation
import UIKit

//measure in T-Shirt coordinates
enum PrintFormat: Double {
    case A3 = 1
    case A4 = 0.5
    case A5 = 0.25
}

//vary depending on T-ShortSize and sure format
struct PrintSize {
    private let magicConstantForWidth = 0.8
    private let magicConstantForHeight = 0.8
    var format = PrintFormat.A3
    var thsirtSize: CGRect
    var width: CGFloat {
        switch format {
        //convert to parts of T-Short coordinates: 4/5 or 3/4 etc.
        case .A3:
            return (180 / 343) * thsirtSize.width
        case .A4:
            return (180 / 343) * thsirtSize.width
        case .A5:
            return (90 / 343) * thsirtSize.width
        }
    }
    var height: CGFloat {
        switch format {
        //convert to parts of T-Short coordinates: 4/5 or 3/4 etc.
        case .A3:
            return (280 / 377) * thsirtSize.height
        case .A4:
            return (140 / 377) * thsirtSize.height
        case .A5:
            return (140 / 377) * thsirtSize.height
        }
    }
}
