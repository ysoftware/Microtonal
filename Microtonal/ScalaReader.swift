//
//  ScalaReader.swift
//  Microtonal
//
//  Created by ysoftware on 10.09.17.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import Foundation

typealias TuningsInfo = (description:String, frequencies:[Double])

func getTunings(from url:String) -> TuningsInfo? {
    guard let url = URL(string: url),
        let string = readFile(url) else { return nil }
    return parseScl(from: string)
}

func readFile(_ path:URL) -> String? {
    return try? String(contentsOf: path, encoding: String.Encoding.utf8)
}

func parseScl(from scala:String) -> TuningsInfo? {
    var tunings:[Double] = []
    var counter = 0
    var description = ""
    
    var failed = false
    scala.enumerateLines { l, _ in
        if l.substring(to: 1) != "!",
            let line = l.replace("\\sg", "")?.trimmingCharacters(in: .whitespacesAndNewlines) {
            
            counter += 1
            
            if counter == 1 { description = line }
            if counter > 2 {
                if line.match("^.*\\.") {
                    guard let centsString = line.replace("\\sg", ""),
                        let cents = Double(centsString)
                        else { return failed = true }
                    tunings.append(pow(2, cents / 1200))
                }
                else if line.match("[0-9]\\/[0-9]") {
                    let ratios = line.components(separatedBy: "/")
                    guard ratios.count == 2,
                        let ratio1 = Double(ratios[0]), let ratio2 = Double(ratios[1])
                        else { return failed = true }
                    tunings.append(ratio1 / ratio2)
                }
                else {
                    guard let value = Double(line)
                        else { return failed = true }
                    tunings.append(value)
                }
            }
        }
    }
    if failed { return nil }
    return (description, tuningToFrequencies(tunings))
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
    return frequencies
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
