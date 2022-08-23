//
//  ViewModel.swift
//  AzureSpeechRecognizer
//
//  Created by kazunori.aoki on 2022/07/28.
//

import Foundation
import Combine

class ViewModel: ObservableObject {

    let recorder = Recorder()

    var cancellables: Set<AnyCancellable> = .init()

    func onAppear() {
        Task {
            _ = await recorder.authorize()
            try! recorder.setupRecording()
        }

        recorder.endRecording
            .sink { _ in
                Task {
                    await self.request()
                }
            }
            .store(in: &cancellables)
    }

    func record() {
        try! recorder.startRecording()
    }

    func stop() {
        recorder.stopRecording()
    }

    func request() async {
        let keyManager = KeyManager()

        let baseUrl = URL(string: "https://japaneast.stt.speech.microsoft.com")!
        let path = "speech/recognition/conversation/cognitiveservices/v1"

        let key = keyManager.getApiKey(key: "AZURE_API_KEY") ?? ""

        let audioStr = FileHelper.audioBase64Text!
        let audioData = Data(base64Encoded: audioStr, options: [])!

        let request = RequestBuilder(path: path)
            .method(.post)
            .queryItem(name: "language", value: "ja-JP")
            .header(name: "Ocp-Apim-Subscription-Key", value: key)
            .header(name: "Content-Type", value: "audio/wav;codec=\"audio/pcm\"")
            .body(audioData)
            .makeRequest(withBaseURL: baseUrl)

        async let (data, _) = URLSession.shared.data(for: request)
        do {
            let response = try await JSONDecoder().decode(Audio.self, from: data)
            print(response.DisplayText)

        } catch {
            print("Error: ", error.localizedDescription)
        }
    }
}
