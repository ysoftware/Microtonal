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
        "pipedum_72b2.scl",
        "savas_diat.scl",
        "serafini-11.scl"
    ]
    
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
        if  currentTuning >= tunings.count {
            currentTuning = 0
        }
        loadTuning(from: BASEURL + tunings[currentTuning])
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
    
    
    @IBOutlet var sliders: [AKPropertyControl]!
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
    
    func loadTuning(from url:String) {
        if let tunings = getTunings(from: url) {
            sound.tunings = tunings.frequencies
            label.text = tunings.description
        }
        else {
            label.text = "No tuning"
            sound.tunings = nil
        }
    }
    
    func setupActions() {
        sliders[0].setup(0, 0, 1, name: "D.Mix") { self.sound.delay.dryWetMix = $0 }
        sliders[1].setup(0.5, 0, 5, name: "D.Time") { self.sound.delay.time = $0 }
        sliders[2].setup(0, 0, 1, name: "Rev.Mix") { self.sound.reverb.dryWetMix = $0 }
        sliders[3].setup(0.1, 0.1, 0.5, name: "Release") { self.sound.osc.releaseDuration = $0 }
        sliders[4].setup(0.1, 0.1, 10, name: "Attack") { self.sound.osc.attackDuration = $0 }
        sliders[5].setup(5, 0.1, 20, name: "Volume") { self.sound.booster.gain = $0 }
    }
    
    func noteOn(note: MIDINoteNumber) {
        sound.play(note: note)
    }
    
    func noteOff(note: MIDINoteNumber) {
        sound.stop(note: note)
    }
}

extension AKPropertyControl {
    func setup(_ value:Double, _ min:Double, _ max:Double, name:String, _ callback: @escaping (Double)->Void) {
        self.value = value
        self.range = min...max
        self.property = name
        self.callback = callback
        self.backgroundColor = .gray
        self.tintColor = .white
        self.callback(value)
        self.fontSize = 15
    }
}

