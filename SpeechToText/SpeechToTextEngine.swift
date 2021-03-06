//
//  SpeechToTextEngine.swift
//  SpeechToText
//
//  Created by Eric Dolecki on 6/12/19.
//  Copyright © 2019 Eric Dolecki. All rights reserved.
//

import UIKit
import Speech

protocol SpeechToTextEngineDelegate {
    func providedResult(value s: String)
    func isListening(value: Bool)
    func isAllowedToRecord(value: Bool)
}

class SpeechToTextEngine: NSObject, SFSpeechRecognizerDelegate
{
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var allowedToRecord = true
    var delegate: SpeechToTextEngineDelegate?
    var speechRecognitionTimeoutTimer: Timer?
    
    override init()
    {
        super.init()
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            switch authStatus {
            case .authorized:
                print("authorized.")
                self.allowedToRecord = true
            case .denied:
                print("deined access.")
                self.allowedToRecord = false
            case .notDetermined:
                print("not determined.")
                self.allowedToRecord = false
            case .restricted:
                print("restricted.")
                self.allowedToRecord = false
            @unknown default:
                print("unknown.")
                self.allowedToRecord = false
            }
            self.delegate?.isAllowedToRecord(value: self.allowedToRecord)
        }
    }
    
    public func requestRecording()
    {
        if allowedToRecord == false {
            self.delegate?.isAllowedToRecord(value: false)
            return
        }
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.delegate?.isListening(value: false)
        } else {
            startRecording()
        }
    }
    
    // We can use this if we determine a command match before the user is done speaking. Premptive.
    public func requestStopRecording() {
        if self.speechRecognitionTimeoutTimer != nil {
            self.speechRecognitionTimeoutTimer!.invalidate()
        }
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.delegate?.isListening(value: false)
        }
    }
    
    private func startRecording()
    {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record)
            try audioSession.setMode(.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession props not set. Error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Might want to check that this exists.
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Cannot create recognition request.")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer!.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                let resultString = result?.bestTranscription.formattedString
                self.delegate?.providedResult(value: resultString ?? "")
                isFinal = (result?.isFinal)!
                
                // Detect end of speech (2 seconds).
                if self.speechRecognitionTimeoutTimer != nil {
                    self.speechRecognitionTimeoutTimer!.invalidate()
                }
                self.speechRecognitionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { (timer) in
                    self.endOfSpeechDetected()
                })
            }
            
            // We're done for now.
            if error != nil || isFinal
            {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.delegate?.isListening(value: false)
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        self.delegate?.isListening(value: true)
    }
    
    func endOfSpeechDetected() {
        print("End of speech detected after 2 seconds.")
        self.requestStopRecording()
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            // We have access to record.
            self.allowedToRecord = true
            self.delegate?.isAllowedToRecord(value: true)
        } else {
            // We do not have access to record.
            self.allowedToRecord = false
            self.delegate?.isAllowedToRecord(value: false)
        }
    }
}
