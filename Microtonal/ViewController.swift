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
        "",
        "efg333.scl",
        "tranh.scl",
        "harmd-15.scl",
        "11-19-mclaren.scl",
        "clipper100.scl",
        "husmann.scl",
        "indian-srutivina.scl", // error
        "indra31.scl",
        "indian_d.scl",
        "kellners.scl",
        "kirnberger48.scl",
        "ligon10.scl",
        "lucy_31.scl",
        "marpurg.scl",
        "mean2nine.scl",
        "pipedum_72b2.scl",
        "savas_diat.scl",
        "serafini-11.scl"
    ]
    
    @IBAction func panic(_ sender: Any) {
        AudioKit.stop()
        AudioKit.start()
        label.text = "Audio restarted"
    }
    
    @IBAction func nextTuning(_ sender: Any) {
        currentTuning += 1
        if  currentTuning >= tunings.count {
            currentTuning = 0
        }
        if let tunings = getTunings(from: "http://ysoftware.ru/scale/scl/" + tunings[currentTuning]) {
            sound.tunings = tunings.frequencies
            label.text = tunings.description
        }
        else {
            label.text = "No tuning"
            sound.tunings = nil
        }
    }
    
    @IBAction func higherOctave(_ sender: Any) {
        keyboard.firstOctave += 1
        label.text = "Octave \(keyboard.firstOctave)"
    }
    
    @IBAction func lowerOctave(_ sender: Any) {
        keyboard.firstOctave -= 1
        label.text = "Octave \(keyboard.firstOctave)"
    }
    
    @IBOutlet var sliders: [AKPropertySlider]!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var keyboard: AKKeyboardView!
    
    // MARK: - Actions
    
    // MARK: - Properties
    
    var currentTuning = 0
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
        sliders[0].setup(0, 0, 1, name: "D.Mix") { self.sound.delay.dryWetMix = $0 }
        sliders[1].setup(0.5, 0, 5, name: "D.Time") { self.sound.delay.time = $0 }
        sliders[2].setup(0, 0, 1, name: "Rev.Mix") { self.sound.reverb.dryWetMix = $0 }
        sliders[3].setup(0.1, 0.1, 1, name: "Rel") { self.sound.osc.releaseDuration = $0 }
        sliders[4].setup(0.1, 0.1, 3, name: "Atk") { self.sound.osc.attackDuration = $0 }
        sliders[5].setup(5, 0, 15, name: "Volume") { self.sound.booster.gain = $0 }
    }
    
    func noteOn(note: MIDINoteNumber) {
        sound.play(note: note)
    }
    
    func noteOff(note: MIDINoteNumber) {
        sound.stop(note: note)
    }
}

extension AKPropertySlider {
    func setup(_ value:Double, _ min:Double, _ max:Double, name:String, _ callback: @escaping (Double)->Void) {
        self.value = value
        self.minimum = min
        self.maximum = max
        self.property = name
        self.callback = callback
        self.bgColor = .gray
        self.bgColor = .white
        self.callback?(value)
    }
}

