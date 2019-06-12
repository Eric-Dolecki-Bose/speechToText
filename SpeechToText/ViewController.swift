//
//  ViewController.swift
//  SpeechToText
//
//  Created by Eric Dolecki on 6/12/19.
//  Copyright © 2019 Eric Dolecki. All rights reserved.
//

import UIKit

enum Commands: String, CaseIterable {
    case Listen = "listen"
    case Start  = "start"
}

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
    func providedResult(value s: String)
    {
        textView.text = s
        
        //let score = s.score(word: "123")
        //let score2 = s.score(word: "123", fuzziness: 0.5) // between 0-1, defaults to nil
        
        //Testing 123
        //print(score, score2) //0.5515151515151515 0.5515151515151515
        
        //Listen
        //let score3 = s.score(word: "Listen", fuzziness: 0.5)
        //print(score3) //1.0
        
        // Loop through commands looking for a good match.
        let lowercasedString = s.lowercased()
        for command in Commands.allCases {
            let score4 = lowercasedString.score(word: command.rawValue)
            if score4 > 0.65 {
                if command == .Listen {
                    print("We found listen.")
                } else if command == .Start {
                    print("We found start.")
                }
            }
        }
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

