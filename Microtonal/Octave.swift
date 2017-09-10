//
//  Keyboard.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import UIKit

protocol OctaveDelegate:class {
    func didPressKey(_ octave:Octave, key:Int)
    func didReleaseKey(_ octave:Octave, key:Int)
}

final class Octave:UIView, KeyDelegate {
    
    @IBOutlet var keys: [UIView]!
    
    weak var delegate:OctaveDelegate?
    
    // MARK: - Key Delegate
    
    func didPressKey(_ key: Key) {
        delegate?.didPressKey(self, key: key.key)
    }
    
    func didReleaseKey(_ key: Key) {
        delegate?.didReleaseKey(self, key: key.key)
    }
    
}
