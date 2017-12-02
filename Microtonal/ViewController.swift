//
//  ViewController.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//


import UIKit
import AudioKit
import AudioKitUI

fileprivate let BASEURL = "http://ysoftware.ru/scale/scl/"

class ViewController: UIViewController, AKKeyboardDelegate {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet var sliders: [AKSlider]!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var keyboard: AKKeyboardView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var midiLabel: UILabel!
    
    // MARK: - Actions
    
    @IBAction func record(_ sender: Any) {
        if sound.recorder.isRecording {
            sound.recorder.stop()
            recordButton.setTitle("Record", for: .normal)
            shareButton.isHidden = false
        }
        else {
            try? sound.recorder.reset()
            try? sound.recorder.record()
            recordButton.setTitle("Stop", for: .normal)
            shareButton.isHidden = true
        }
    }
    
    @IBAction func shareRecord(_ sender: Any) {
        sound.recorder.audioFile?.exportAsynchronously(
            name: "#nonmusic",
            baseDir: .temp,
            exportFormat: .wav, callback: { file, error in
                if let url = file?.url {
                    let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    vc.popoverPresentationController?.sourceView = self.shareButton
                    self.present(vc, animated: true)
                }
        })
    }

    @IBAction func loadTuning(_ sender: Any) {
        let alert = UIAlertController(title: "Load a tuning",
                                      message: "Name or url of an .scl file.",
                                      preferredStyle: .alert)
        alert.addTextField ()
        
        alert.addAction(UIAlertAction(title: "Load", style: .default, handler: { [weak alert] (_) in
            guard let a = alert, let url = a.textFields![0].text else { return }
            
            if url.contains("http") {
                self.loadTuning(from: url)
            }
            else if url.contains(".scl") {
                self.loadTuning(from: BASEURL + url)
            }
            else {
                self.loadTuning(from: BASEURL + url + ".scl")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func panic(_ sender: Any) {
        AudioKit.stop()
        AudioKit.start()
        label.text = "Audio restarted"
    }
    
    @IBAction func nextTuning(_ sender: Any) {
        currentTuning += 1
        if  currentTuning >= Tunings.tunings.count {
            currentTuning = 0
        }
		loadTuning(from: BASEURL + Tunings.tunings[currentTuning])
    }
    
    @IBAction func higherOctave(_ sender: Any) {
        if keyboard.firstOctave < 8 {
            keyboard.firstOctave += 1
            label.text = "Octaves \(keyboard.firstOctave), \(keyboard.firstOctave+1)"
        }
    }
    
    @IBAction func lowerOctave(_ sender: Any) {
        if keyboard.firstOctave > 0 {
            keyboard.firstOctave -= 1
            label.text = "Octaves \(keyboard.firstOctave), \(keyboard.firstOctave+1)"
        }
    }
    
    // MARK: - Properties
    
    var currentTuning = 0
    let sound = Sound()
    var midiReceiver:MIDIReceiver!
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyboard.delegate = self
        keyboard.polyphonicMode = true
        keyboard.octaveCount = 2
        keyboard.firstOctave = 3
        keyboard.keyOnColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        midiReceiver = MIDIReceiver(sound)
    
        setupActions()
    }
    
    func setupActions() {
        shareButton.isHidden = true
        
        sliders[6].setup(0, 0, 3, name: "Wave form") { [unowned self] in
            self.sound.waveForm(at: Int($0))
        }
        sliders[6].discreteValues = [0, 1, 2, 3]
        
        sliders[7].setup(0.1, 0.1, 10, name: "Attack") { [unowned self] in
            self.sound.osc.attackDuration = $0
        }
        sliders[8].setup(0.5, 0, 5, name: "D.Time") { [unowned self] in
            self.sound.delay.time = $0
        }
        sliders[9].setup(2000, 100, 3500, name: "Low Pass") { [unowned self] in
            self.sound.filter.cutoffFrequency = $0
        }
        sliders[10].setup(0.1, 0.1, 1.99, name: "Resonance") { [unowned self] in
            self.sound.filter.resonance = $0
        }
        sliders[11].setup(13, 3, 13, name: "Bitcrush Depth") { [unowned self] value in
            self.sound.bitcrusher.bitDepth = value
            if value == 13 {
                self.sound.bitcrusher.stop()
            }
            else if self.sound.bitcrusher.isStopped {
                self.sound.bitcrusher.start()
            }
        }
        
        sliders[0].setup(1, 1, 15, name: "Gain") { [unowned self] in
            self.sound.booster.gain = $0
        }
        sliders[1].setup(0.1, 0.1, 0.5, name: "Release") { [unowned self] in
            self.sound.osc.releaseDuration = $0
        }
        sliders[2].setup(0, 0, 1, name: "D.Mix") { [unowned self] in
            self.sound.delay.dryWetMix = $0
        }
        sliders[3].setup(0, 0, 1, name: "Rev.Mix") { [unowned self] in
            self.sound.reverb.dryWetMix = $0
        }
        sliders[4].setup(0.1, 0, 1.99, name: "Saturation") { [unowned self] in self.sound.filter.resonance = $0
        }
        sliders[5].setup(0.5, 0, 1, name: "Delay FB") { [unowned self] in
            self.sound.delay.feedback = $0
        }
    }
    
	func loadTuning(from url:String) {
		guard let url = URL(string: url) else { return }
        if let freqs = Tunings.loadFrequencies(from: url) {
            sound.tuningTable.tuningTable(fromFrequencies: freqs)
            label.text = url.lastPathComponent
        }
        else {
            label.text = "No tuning"
            sound.tuningTable.defaultTuning()
        }
    }
    
    func noteOn(note: MIDINoteNumber) {
        sound.play(note: note)
    }
    
    func noteOff(note: MIDINoteNumber) {
        sound.stop(note: note)
    }
}

