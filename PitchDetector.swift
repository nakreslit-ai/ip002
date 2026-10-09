import AVFoundation
import Accelerate
import Combine

@MainActor
final class PitchDetector: ObservableObject {
    @Published var currentNote: DetectedNote?
    @Published var amplitude: Float = 0
    @Published var isRunning = false
    @Published var errorMessage: String?
    
    private let engine = AVAudioEngine()
    private var isSetup = false
    private let bufferSize: AVAudioFrameCount = 4096
    private let minAmplitude: Float = 0.02          // prah šumu
    
    func start() {
        Task {
            await requestPermissionAndStart()
        }
    }
    
    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        currentNote = nil
    }
    
    private func requestPermissionAndStart() async {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            
            let granted = await withCheckedContinuation { cont in
                session.requestRecordPermission { cont.resume(returning: $0) }
            }
            
            guard granted else {
                errorMessage = "Mikrofon není povolen. Povolte ho v Nastavení."
                return
            }
            
            setupAndStartEngine()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func setupAndStartEngine() {
        guard !isSetup else {
            try? engine.start()
            isRunning = true
            return
        }
        
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        
        input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            self.process(buffer: buffer)
        }
        
        do {
            try engine.start()
            isSetup = true
            isRunning = true
        } catch {
            errorMessage = "Nelze spustit audio engine: \(error.localizedDescription)"
        }
    }
    
    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // RMS amplituda
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        DispatchQueue.main.async {
            self.amplitude = rms
        }
        
        guard rms > minAmplitude else {
            DispatchQueue.main.async { self.currentNote = nil }
            return
        }
        
        // Jednoduchá autokorelace (YIN-like) pro F0
        let frequency = estimatePitch(samples: channelData, count: frameLength, sampleRate: buffer.format.sampleRate)
        
        if let freq = frequency, let note = NoteMapper.note(from: freq) {
            DispatchQueue.main.async {
                self.currentNote = note
            }
        }
    }
    
    /// Velmi jednoduchá detekce výšky pomocí autokorelace
    private func estimatePitch(samples: UnsafePointer<Float>, count: Int, sampleRate: Double) -> Double? {
        let minLag = Int(sampleRate / 1000)   // ~1000 Hz max
        let maxLag = Int(sampleRate / 60)     // ~60 Hz min
        
        guard maxLag < count else { return nil }
        
        var bestLag = 0
        var bestCorr: Float = -1
        
        // Normalizovaná autokorelace (zjednodušená)
        for lag in minLag..<maxLag {
            var sum: Float = 0
            vDSP_dotpr(samples, 1, samples.advanced(by: lag), 1, &sum, vDSP_Length(count - lag))
            
            if sum > bestCorr {
                bestCorr = sum
                bestLag = lag
            }
        }
        
        guard bestLag > 0 else { return nil }
        return sampleRate / Double(bestLag)
    }
}
