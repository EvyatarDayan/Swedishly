//
//  ManualSpeechRecognizer.swift
//  Swedishly
//

import Foundation
import Combine
import Speech
import AVFoundation

class SpeechRecognizer: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    /// When set, the view should show this message (e.g. missing privacy keys).
    @Published var errorMessage: String?
    
    private var currentCompletion: ((String) -> Void)?
    private var onRecordingStopped: (() -> Void)?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    override init() {
        super.init()
    }
    
    /// Returns true if Info.plist has the required privacy keys (so requesting authorization won't crash).
    static var hasSpeechPrivacyKeys: Bool {
        let hasSpeech = Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil
        let hasMic = Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil
        return hasSpeech && hasMic
    }
    
    func startRecording(language: String, completion: @escaping (String) -> Void) {
        if isRecording {
            stopRecording()
            return
        }
        self.currentCompletion = completion
        self.errorMessage = nil
        guard Self.hasSpeechPrivacyKeys else {
            errorMessage = "To use dictation, add Privacy - Speech Recognition Usage Description and Privacy - Microphone Usage Description in Xcode: select the Swedishly target → Info → Custom iOS Target Properties."
            DispatchQueue.main.async {
                self.currentCompletion = nil
                self.onRecordingStopped?()
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        self?.startSimpleRecording(language: language)
                    case .denied:
                        print("Speech recognition authorization denied")
                        self?.currentCompletion = nil
                        self?.isRecording = false
                        self?.onRecordingStopped?()
                    case .restricted:
                        print("Speech recognition authorization restricted")
                        self?.currentCompletion = nil
                        self?.isRecording = false
                        self?.onRecordingStopped?()
                    case .notDetermined:
                        print("Speech recognition authorization not determined")
                        self?.currentCompletion = nil
                        self?.isRecording = false
                        self?.onRecordingStopped?()
                    @unknown default:
                        self?.currentCompletion = nil
                        self?.isRecording = false
                        self?.onRecordingStopped?()
                    }
                }
            }
        }
    }
    
    private func startSimpleRecording(language: String) {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) else {
            print("Speech recognizer not available for language: \(language)")
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self?.transcribedText = text
                    self?.currentCompletion?(text)
                }
                if result.isFinal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.stopRecording()
                    }
                }
            }
            if error != nil {
                self?.stopRecording()
            }
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            
            try audioEngine.start()
            self.audioEngine = audioEngine
            self.recognitionRequest = request
            self.recognitionTask = task
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("Error starting speech recognition: \(error)")
            stopRecording()
        }
    }
    
    func stopRecording() {
        guard audioEngine != nil || recognitionRequest != nil || recognitionTask != nil else {
            DispatchQueue.main.async {
                self.isRecording = false
                self.onRecordingStopped?()
            }
            return
        }
        audioEngine?.stop()
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        currentCompletion = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.onRecordingStopped?()
        }
    }
    
    func setOnRecordingStopped(_ callback: @escaping () -> Void) {
        self.onRecordingStopped = callback
    }
}
