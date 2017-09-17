//
//  Sound.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import AudioKit

final class Sound {
    
    var waveForm:AKTableType = .sine
    
    var tunings:[Double]?
    
    var osc:AKOscillatorBank!
    var delay:AKDelay!
    var reverb:AKReverb!
    var bitcrusher:AKBitCrusher!
    var filter:AKKorgLowPassFilter!
    var booster:AKBooster!
    var recorder:AKNodeRecorder!
    var limiter:AKPeakLimiter!
    
    var a:Double = 440
    
    func setup() {
        let table = AKTable(waveForm, phase: 0, count: 4096)
        
        osc = AKOscillatorBank(waveform: table)
        osc.attackDuration = 0.1
        osc.releaseDuration = 0.1
        
        reverb = AKReverb(osc)
        reverb.dryWetMix = 0
        
        delay = AKDelay(reverb)
        delay.dryWetMix = 0
        delay.time = 0.5
        delay.start()
        
        booster = AKBooster(delay, gain: 1)
        
        filter = AKKorgLowPassFilter(booster)
        
        limiter = AKPeakLimiter(filter)
        
        try! recorder = AKNodeRecorder(node: limiter)
        AudioKit.output = limiter
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
    
    func waveForm(at index: Int) {
        AudioKit.stop()
        waveForm = [AKTableType.sawtooth,
                    AKTableType.sine,
                    AKTableType.triangle,
                    AKTableType.square][index]
        setup()
    }
}
