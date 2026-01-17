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
    
    // MARK: - Optimization: Pre-warming
    
    /// Boots the audio engine and prepares the recognizer to minimize latency on first use.
    public func warmUp() {
        Task.detached(priority: .userInitiated) {
            _ = self.audioEngine.inputNode
            self.audioEngine.prepare()
            print("[VoiceEngine] Pre-warmed audio engine.")
        }
    }
    
    // MARK: - Speech-to-Text
    
    public func startListening() throws {
        guard !isListening else { return }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true // Force high-speed local processing
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Lower buffer size (512) for more frequent updates (latency reduction)
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        // If not already running from warmUp
        if !audioEngine.isRunning {
            audioEngine.prepare()
            try audioEngine.start()
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                Task { @MainActor in
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
    
    deinit {
        stopListening()
        stopSpeaking()
        print("[VoiceEngine] Deinitialized and cleaned up audio resources.")
    }
    
    public func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionTask?.finish() // Allow task to wrap up gracefully
        recognitionTask = nil
        
        Task { @MainActor in
            self.isListening = false
        }
    }
    
    // MARK: - Text-to-Speech
    
    public func speak(_ text: String, rate: Float = 0.5) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        
        // Attempt to use Apple's high-fidelity "Ava" or Siri premium voices if available
        if let premiumVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_Ava_en-US_compact") ?? 
                            AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = premiumVoice
        }
        
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
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
