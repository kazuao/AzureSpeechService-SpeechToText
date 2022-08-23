//
//  SpeechService.swift
//  Talking-RIDER
//
//  Created by kazunori.aoki on 2022/01/07.
//

import Foundation
import AVFoundation



final class SpeechService: NSObject{
    
    // MARK: Singleton
    static let shared = SpeechService()
    private override init() {
        super.init()
    }
    
    
    // MARK: Property
    private var player: AVAudioPlayer?
    private var contents: [String] = []
    
    // Setting
    private let decreaseVolume: Float = 0.1
    private let increaseVolume: Float = 1.0
    
    
    // MARK: Public
    func speech(audioContent: String) {
        contents.append(audioContent)
        speech()
    }
    
    func decrease() {
        player?.volume = decreaseVolume
    }
    
    func increase() {
        player?.volume = increaseVolume
    }
    
    func reset() {
        stop()
        increase()
        contents = []
    }
}


// MARK: Private
private extension SpeechService {
    func speech() {
        if player?.isPlaying ?? false { return }
        
        if let content = contents.first {
            guard let audioData = Data(base64Encoded: content) else { return }
            
            start(audioData: audioData)
        }
    }
    
    func start(audioData: Data) {
        player = try? AVAudioPlayer(data: audioData)
        player?.delegate = self
        player?.play()
    }
    
    func stop() {
        guard player != nil else { return }
        
        player?.stop()
        player?.delegate = nil
        player = nil
    }
}


// MARK: AVAudioPlayerDelegate
extension SpeechService: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
        
        contents.removeFirst()
        if !contents.isEmpty {
            speech()
        }
    }
}
