//
//  Key.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import UIKit

protocol KeyDelegate:class {
    func didPressKey(_ key:Key)
    func didReleaseKey(_ key:Key)
}

final class Key:UIView {
    
    @IBInspectable var key:Int = 0
    
    var isBlack:Bool {
        return [1, 3, 6, 8, 10].contains(key)
    }
    
    weak var delegate:KeyDelegate?
    var isPressed:Bool = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressKey()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if frame.contains(touches.first!.location(in: self)) {
            pressKey()
        }
        else {
            releaseKey()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseKey()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseKey()
    }
    
    func pressKey() {
        if !isPressed {
            delegate?.didPressKey(self)
            backgroundColor = isBlack ? .keyBlackPressed : .keyWhitePressed
            isPressed = true
        }
    }
    
    func releaseKey() {
        if isPressed {
            delegate?.didReleaseKey(self)
            backgroundColor = isBlack ? .keyBlack : .keyWhite
            isPressed = false
        }
    }
}
