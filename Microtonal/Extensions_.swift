//
//  Extensions_.swift
//  Microtonal
//
//  Created by ysoftware on 30.10.2017.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import Foundation
import AudioKit
import AudioKitUI

extension AKPropertyControl {
    func setup(_ value:Double, _ min:Double, _ max:Double, name:String, _ callback: @escaping (Double)->Void) {
        self.value = value
        self.range = min...max
        self.property = name
        self.backgroundColor = .gray
        self.tintColor = .white
        self.callback = callback
        self.callback(value)
        self.fontSize = 15
    }
}
