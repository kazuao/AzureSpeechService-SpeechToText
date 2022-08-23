//
//  Audio.swift
//  AzureSpeechRecognizer
//
//  Created by kazunori.aoki on 2022/08/23.
//

import Foundation

struct Audio: Codable {
    var RecognitionStatus: String
    var DisplayText: String
    var Offset: Int
    var Duration: Int
}
