//
//  MidiReceiver.swift
//  Microtonal
//
//  Created by ysoftware on 25.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import Foundation
import AudioKit

final class MIDIReceiver:AKMIDIListener {
    
    weak var sound:Sound?
    let midi = AKMIDI()
    
    init(_ sound:Sound) {
        midi.openInput()
        midi.addListener(self)
        
        self.sound = sound
    }
    
    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        sound?.play(note: noteNumber, velocity: velocity)
    }
    
    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        sound?.stop(note: noteNumber)
    }
    
    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel) {
        sound?.pitchBend(2 / (16384.0 / Double(pitchWheelValue)))
    }
}
