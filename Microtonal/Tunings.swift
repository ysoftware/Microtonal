//
//  TuningController.swift
//  Microtonal
//
//  Created by ysoftware on 30.10.2017.
//  Copyright © 2017 ysoftware. All rights reserved.
//

import Foundation
import AudioKit

struct Tunings {
    static let tunings = [
        "",
        "arist_chrom.scl",      // 7
        "efg333.scl",           // 4
        "efg3357.scl",          // 12...
        "kellner.scl",
        "12-22.scl",
        //        "12-22h.scl",
        //        "12-27.scl",
        //        "12-31.scl",
        //        "12-43.scl",
        //        "12-46.scl",
        //        "12-46p.scl",
        "24-41.scl",            // 24...
        //        "24-60.scl",
        //        "24-80.scl",
        //        "24-94.scl",
        "12-79mos159et.scl",
        "12-yarman24c.scl",
        "tranh3.scl",           // 6?
        "harmd-15.scl",         // 7
        "11-19-mclaren.scl",    // 11
        "clipper100.scl",       // 17
        "husmann.scl",          // 6
        "indian_d.scl",         // 7
        "marpurg.scl",
        "savas_diat.scl"
    ]
    
    static func loadFrequencies(from tuningURL:URL) -> [AKTuningTable.Frequency]? {
        if let scalaString = readFile(tuningURL),
            let frequencies = AKTuningTable().frequencies(fromScalaString: scalaString) {
            return frequencies
        }
        else {
            return nil
        }
    }
    
    private static func readFile(_ path:URL) -> String? {
        return try? String(contentsOf: path, encoding: String.Encoding.utf8)
    }
    
}
