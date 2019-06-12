//
//  ViewController.swift
//  SpeechToText
//
//  Created by Eric Dolecki on 6/12/19.
//  Copyright © 2019 Eric Dolecki. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SpeechToTextEngineDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    var sttEngine:SpeechToTextEngine!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sttEngine = SpeechToTextEngine()
        sttEngine.delegate = self
    }
    
    @IBAction func micButtonTapped(_ sender: Any) {
        sttEngine.requestRecording()
    }
    
    // MARK: - STTEngine Delegates
    
    // This string data streams in as recorded voice is processed by the SpeechToTextEngine.
    func providedResult(value s: String) {
        textView.text = s
    }
    
    func isListening(value: Bool) {
        if !value {
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func isAllowedToRecord(value: Bool) {
        // This must happen on the main UI thread.
        OperationQueue.main.addOperation {
            self.microphoneButton.isEnabled = value
        }
        print("We are allowed to record: \(value).")
    }
}

