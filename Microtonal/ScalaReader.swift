//
//  ScalaReader.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import Foundation

// TO-DO: sparschuh_53in13lim.scl
// TO-DO: kwazy.scl - wtf is g=162.741892 ??
// TO-DO: Line 2 is note count

public struct Tuning {
    var noteCount:Int = 12
    var frequencies:[Double] = []
    var description:String = ""
}

func getTunings(from url:String) -> Tuning? {
    guard let url = URL(string: url),
        let string = readFile(url) else {
            print("Error 0: url not found")
            return nil
    }
    return parseScl(from: string)
}

func parseScl(from scala:String) -> Tuning? {
    var tunings:[Double] = []
    var counter = 0
    var description = ""
    var noteCount = 0
    
    var failed = false
    scala.enumerateLines { l, _ in
        if l.substring(to: 1) != "!",
            let line = l.replace("\\sg", "")?.trimmingCharacters(in: .whitespaces) {
            
            counter += 1
            
            if counter == 1 { description = line }
            if counter == 2 { noteCount = Int(line) ?? 0 }
            if counter > 2 {
                if line.match("^.*\\.") {
                    guard
                        let centsString = line.replace("\\sg", "")?
                            .replace("cents", "")?
                            .trimmingCharacters(in: .whitespaces),
                        let cents = Double(centsString)
                        else {
                            print("Error 1 in line \(line)")
                            return failed = true
                    }
                    tunings.append(pow(2, cents / 1200))
                }
                else if line.match("[0-9]\\/[0-9]") {
                    let ratios = line.components(separatedBy: "/")
                    guard ratios.count == 2,
                        let ratio1 = Double(ratios[0]), let ratio2 = Double(ratios[1])
                        else {
                            print("Error 2 in line \(line)")
                            return failed = true
                    }
                    tunings.append(ratio1 / ratio2)
                }
                else {
                    guard let value = Double(line)
                        else {
                            print("Error 3 in line \(line)")
                            return failed = true
                    }
                    tunings.append(value)
                }
            }
        }
    }
    if failed { return nil }
    
    var tuning = Tuning()
    tuning.description = description
    tuning.frequencies = tuningToFrequencies(tunings)
    tuning.noteCount = noteCount
    
    return tuning
}

func tuningToFrequencies(_ tunings:[Double]) -> [Double] {
    let baseNote = 48
    let baseFrequency = 261.625565300598623
    
    let notesPerOctave = tunings.count
    var frequencies:[Double] = []
    
    for i in 0...128 {
        let note = i - baseNote
        let degree = abs(note % notesPerOctave)
        let octave:Int = Int(floor(Double(note / notesPerOctave)))
        var frequency = baseFrequency * pow(tunings[notesPerOctave - 1],
                                            Double((octave * notesPerOctave) / notesPerOctave))
        if degree > 0 {
            frequency *= tunings[degree - 1]
        }
        frequency = max(0.0, min(22050.0, frequency))
        frequencies.append(frequency)
    }
    return frequencies.sorted()
}

extension String {
    func replace(_ pattern:String, _ replace:String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSMakeRange(0, characters.count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replace)
    }
    func match(_ pattern:String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}

func readFile(_ path:URL) -> String? {
    return try? String(contentsOf: path, encoding: String.Encoding.utf8)
}
