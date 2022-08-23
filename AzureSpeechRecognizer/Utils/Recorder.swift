//
//  Recorder.swift
//  Talking-RIDER
//
//  Created by kazunori.aoki on 2021/12/27.
//

import SwiftUI
import AVFoundation
import Speech
import Combine

final class Recorder: ObservableObject {

    // MARK: Property
    private var recorder: AVAudioRecorder!

    // MARK: Notification
    @Published var endRecording = PassthroughSubject<Void, Never>()

    
    // MARK: Public
    func authorize() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    continuation.resume(returning: true)
                case .notDetermined, .denied, .restricted:
                    continuation.resume(returning: false)
                default:
                    assertionFailure("not authorized")
                }
            }
        }
    }

    func setupRecording() throws {
        let recordingSettings: [String: Any] = [
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: 16,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 16_000
        ]

        recorder = try AVAudioRecorder(url: FileHelper.soundFileURL(), settings: recordingSettings)
    }

    func startRecording() throws {
        stop()

        let audioSession = AVAudioSession.sharedInstance()

        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)

        recorder.record()
    }

    func stopRecording() {
        stop()
        endRecording.send()
    }

    func stop() {
        recorder.stop()
    }
}


struct FileHelper {

    static var audioBase64Text: String? {
        return convertAudioToBase64(url: soundFileURL())
    }

    static func soundFileURL() -> URL {
        let documentPath: [URL] = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDir: URL = documentPath[0]
        return documentDir.appendingPathComponent("sound.wav")
    }

    private static func convertAudioToBase64(url: URL) -> String? {
        guard let data = NSData(contentsOf: url) else {
            return nil
        }

        return data.base64EncodedString()
    }
}
