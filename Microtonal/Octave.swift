//
//  Keyboard.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import UIKit

protocol OctaveDelegate:class {
    func didPressKey(_ object:Octave, _ octave:Int, _ key:Int)
    func didReleaseKey(_ object:Octave, _ octave:Int, _ key:Int)
}

@IBDesignable final class Octave:UIView, KeyDelegate {
    
    // MARK: - Views
    
    @IBOutlet var keys: [Key]! {
        didSet {
            for s in keys {
                s.delegate = self
            }
        }
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        fromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fromNib()
    }
    
    // MARK: - Properties
    
    @IBInspectable var octave:Int = 3
    weak var delegate:OctaveDelegate?
    
    // MARK: - Key Delegate
    
    func didPressKey(_ key: Key) {
        delegate?.didPressKey(self, octave, key.key)
    }
    
    func didReleaseKey(_ key: Key) {
        delegate?.didReleaseKey(self, octave, key.key)
    }
    
}
