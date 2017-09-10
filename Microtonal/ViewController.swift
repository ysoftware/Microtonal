//
//  ViewController.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//



/*
 
 http://ysoftware.ru/scale/scl/efg333.scl
 
 */

import UIKit
import AudioKit

class ViewController: UIViewController, AKKeyboardDelegate {
    
    @IBOutlet var sliders: [AKPropertySlider]!
    
    @IBOutlet weak var keyboard: AKKeyboardView!
    
    // MARK: - Actions
    
    // MARK: - Properties
    
    let sound = Sound()
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyboard.delegate = self
        keyboard.polyphonicMode = true
        keyboard.firstOctave = 4
        keyboard.octaveCount = 1
        
        sound.setup()
        setupActions()
        
        let tunings = getTunings(from: "http://ysoftware.ru/scale/scl/tranh.scl")
        print(tunings!.description)
        tunings!.frequencies.forEach { print($0) }
        sound.tunings = tunings?.frequencies
    }
    
    func setupActions() {
//        sliders[0].setup(min: 340, max: 540, name: "A4") { self.sound.a = $0 }
        sliders[1].setup(min: 0, max: 1, name: "Delay mix") { self.sound.delay.dryWetMix = $0 }
        sliders[2].setup(min: 0, max: 3, name: "Delay Time") { self.sound.delay.time = $0 }
        
        sliders[3].setup(min: 0, max: 10, name: "Osc Ramp") { self.sound.osc.rampTime = $0 }
        sliders[4].setup(min: 0, max: 1, name: "Reverb mix") { self.sound.reverb.dryWetMix = $0 }
        sliders[5].setup(min: 0, max: 4, name: "Waveform") { val in
            let waveForm: AKTableType
            switch val {
            case 0..<1: waveForm = .sine
            case 1..<2: waveForm = .triangle
            case 2..<3: waveForm = .square
            case 3..<4: waveForm = .sawtooth
            default: return
            }
            self.sound.osc.waveform = AKTable(waveForm, phase: 0, count: 0)
            AudioKit.stop()
            AudioKit.start()
        }
        
        sliders[6].setup(min: 0.1, max: 3, name: "Release") { self.sound.osc.releaseDuration = $0 }
        sliders[7].setup(min: 0.1, max: 3, name: "Attack") { self.sound.osc.attackDuration = $0 }
//        sliders[8].setup(min: 0, max: 3, name: "Release") { self.sound.envelope.releaseDuration = $0 }
        
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

