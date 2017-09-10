//
//  Keyboard.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import Foundation

protocol KeyboardDelegate:class {
    func didPressKey(_ key:Int)
    func didReleaseKey(_ key:Int)
}

final class Keyboard: OctaveDelegate {
    
    // MARK: - Properties
    
    weak var delegate:KeyboardDelegate?
    var octaves:[Octave] = []
    
    // MARK: - Init
    
    func setup(with octaves:[Octave]) {
        self.octaves = octaves
        for s in octaves {
            s.delegate = self
        }
    }
    
    // MARK: - Delegate
    
    func didPressKey(_ object: Octave, _ octave: Int, _ key: Int) {
        delegate?.didPressKey(12 * octave + key)
    }
    
    func didReleaseKey(_ object: Octave, _ octave: Int, _ key: Int) {
        delegate?.didReleaseKey(12 * octave + key)
    }
    
    
    
}
