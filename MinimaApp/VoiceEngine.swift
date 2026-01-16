import Speech
import AVFoundation

/// "The Voice"
/// Handles Speech-to-Text (Whisper/on-device) and Text-to-Speech.
public class VoiceEngine: NSObject, ObservableObject {
    public static let shared = VoiceEngine()
    
    // Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Text-to-Speech
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published public var isListening: Bool = false
    @Published public var transcribedText: String = ""
    
    public override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Permissions
    
    public func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        let audioStatus = await AVCaptureDevice.requestAccess(for: .audio)
        
        return speechStatus && audioStatus
    }
    
    // MARK: - Speech-to-Text
    
    public func startListening() throws {
        guard !isListening else { return }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self?.stopListening()
            }
        }
        
        DispatchQueue.main.async {
            self.isListening = true
        }
    }
    
    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    // MARK: - Text-to-Speech
    
    public func speak(_ text: String, rate: Float = 0.5) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    public func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension VoiceEngine: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Callback when speech finishes
    }
}
