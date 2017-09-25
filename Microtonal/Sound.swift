//
//  Sound.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import AudioKit

final class Sound {
    var waveForm:AKTableType = .sawtooth
    
    var osc:AKOscillatorBank!
    var delay:AKDelay!
    var reverb:AKReverb!
    var bitcrusher:AKBitCrusher!
    var filter:AKKorgLowPassFilter!
    var booster:AKBooster!
    var recorder:AKNodeRecorder!
    var limiter:AKPeakLimiter!
    var tuningTable:AKTuningTable!
    
    var a:Double = 440
    
    func setup() {
        let table = AKTable(waveForm)
        tuningTable = AKPolyphonicNode.tuningTable
        
        osc = AKOscillatorBank(waveform: table)
        osc.attackDuration = 0.1
        osc.releaseDuration = 0.1
        
        delay = AKDelay(osc)
        delay.dryWetMix = 0
        delay.time = 0.5
        
        reverb = AKReverb(delay)
        reverb.dryWetMix = 0
        
        booster = AKBooster(reverb, gain: 1)
        
        filter = AKKorgLowPassFilter(booster)
        
        limiter = AKPeakLimiter(filter)
        
        bitcrusher = AKBitCrusher(limiter, bitDepth: 24)
        
        let output = AKMixer([bitcrusher, limiter]) // <= change this
        
        try! recorder = AKNodeRecorder(node: output)
        AudioKit.output = output
        AudioKit.start()
        
        delay.start()
        reverb.start()
        filter.start()
        limiter.start()
        bitcrusher.start()
    }
    
    func play(note:MIDINoteNumber, velocity:MIDIVelocity = 80) {
        let frequency = AKPolyphonicNode.tuningTable.frequency(forNoteNumber: note)
        osc.play(noteNumber: note, velocity: velocity, frequency: frequency)
    }
    
    func stop(note:MIDINoteNumber) {
        osc.stop(noteNumber: note)
    }
    
    func pitchBend(_ semitones:Double) {
        osc.pitchBend = semitones
    }
    
    func waveForm(at index: Int) {
        AudioKit.stop()
        let newWaveForm = [AKTableType.sawtooth,
                           AKTableType.sine,
                           AKTableType.triangle,
                           AKTableType.square][index]
        waveForm = newWaveForm
        setup()
    }
}
