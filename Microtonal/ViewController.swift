//
//  ViewController.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//



/*
 
 
 
 
 
 */

import UIKit
import AudioKit

class ViewController: UIViewController, AKKeyboardDelegate {
    
    let tunings = [
        "efg333.scl",
        "tranh.scl",
        "harmd-15.scl",
        "11-19-mclaren.scl",
        "clipper100.scl",
        ""
    ]
    
    @IBAction func panic(_ sender: Any) {
        AudioKit.stop()
        AudioKit.start()
    }
    
    @IBAction func nextTuning(_ sender: Any) {
        if let tunings = getTunings(from: "http://ysoftware.ru/scale/scl/" + tunings.randomElement()) {
            sound.tunings = tunings.frequencies
            tuningLabel.text = tunings.description
        }
        else {
            tuningLabel.text = "no tuning"
            sound.tunings = []
        }
    }
    
    @IBAction func higherOctave(_ sender: Any) {
        keyboard.firstOctave += 1
    }
    
    @IBAction func lowerOctave(_ sender: Any) {
        keyboard.firstOctave -= 1
    }
    
    @IBOutlet var sliders: [AKPropertySlider]!
    @IBOutlet weak var tuningLabel: UILabel!
    @IBOutlet weak var keyboard: AKKeyboardView!
    
    // MARK: - Actions
    
    // MARK: - Properties
    
    let sound = Sound()
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyboard.delegate = self
        keyboard.polyphonicMode = true
        keyboard.firstOctave = 3
        keyboard.octaveCount = 2
        
        sound.setup()
        setupActions()
    }
    
    func setupActions() {
        sliders[0].setup(min: 0, max: 1, name: "D.Mix") { self.sound.delay.dryWetMix = $0 }
        sliders[1].setup(min: 0, max: 3, name: "D.Time") { self.sound.delay.time = $0 }
        sliders[2].setup(min: 0, max: 1, name: "Rev.Mix") { self.sound.reverb.dryWetMix = $0 }
        sliders[3].setup(min: 0.1, max: 2, name: "Rel") { self.sound.osc.releaseDuration = $0 }
        sliders[4].setup(min: 0.1, max: 2, name: "Atk") { self.sound.osc.attackDuration = $0 }
        sliders[5].setup(min: 0, max: 13, name: "Volume") { self.sound.booster.gain = $0 }
    }
    
    func noteOn(note: MIDINoteNumber) {
        sound.play(note: note)
    }
    
    func noteOff(note: MIDINoteNumber) {
        sound.stop(note: note)
    }
}

extension AKPropertySlider {
    func setup(min:Double, max:Double, name:String, _ callback: @escaping (Double)->Void) {
        self.minimum = min
        self.maximum = max
        self.property = name
        self.callback = callback
    }
}

