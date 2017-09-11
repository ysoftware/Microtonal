//
//  Sound.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import AudioKit

final class Sound {
    
    var tunings:[Double]?
    
    var osc:AKOscillatorBank!
    var delay:AKDelay!
    var reverb:AKReverb!
    var bitcrusher:AKBitCrusher!
    var booster:AKBooster!
    
    var a:Double = 440
    
    func setup() {
        osc = AKOscillatorBank()
        osc.attackDuration = 0.1
        osc.releaseDuration = 0.1
        
        reverb = AKReverb(osc)
        reverb.dryWetMix = 0
        
        delay = AKDelay(reverb)
        delay.dryWetMix = 0
        delay.time = 0.5
        
        booster = AKBooster(delay, gain: 5)
        
        AudioKit.output = booster
        AudioKit.start()
    }
    
    func play(note:MIDINoteNumber) {
        if let freqs = tunings, freqs.count >= 128 {
            osc.play(noteNumber: note, velocity: 80, frequency: freqs[Int(note)])
        }
        else {
             osc.play(noteNumber: note, velocity: 80)
        }
    }
    
    func stop(note:MIDINoteNumber) {
        osc.stop(noteNumber: note)
    }
}
