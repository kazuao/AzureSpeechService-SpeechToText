//
//  KeyManager.swift
//  AzureSpeechRecognizer
//
//  Created by kazunori.aoki on 2022/07/28.
//

import Foundation

struct KeyManager {
    private let keyFilePath = Bundle.main.path(forResource: "ApiKey", ofType: "plist")

    func getKeys() -> Dictionary<String, Any>? {
        guard let keyFilePath = keyFilePath else { return nil }
        let configuration = NSDictionary(contentsOfFile: keyFilePath)
        if let dic: [String: Any] = configuration as? [String: Any] {
            return dic
        } else {
            return nil
        }
    }

    func getApiKey(key: String) -> String? {
        guard let keys = getKeys() else { return nil }
        return keys[key] as? String
    }
}
