import Foundation

struct DetectedNote: Equatable {
    let name: String          // "C", "C#", "D" ...
    let octave: Int
    let frequency: Double
    let cents: Double         // odchylka od ideální frekvence
    let midi: Int
    
    var displayName: String { "\(name)\(octave)" }
}

enum NoteMapper {
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    static let a4Frequency: Double = 440.0
    
    static func note(from frequency: Double) -> DetectedNote? {
        guard frequency > 20, frequency < 5000 else { return nil }
        
        // MIDI number
        let midi = 69 + 12 * log2(frequency / a4Frequency)
        let roundedMidi = Int(round(midi))
        let cents = (midi - Double(roundedMidi)) * 100
        
        let noteIndex = ((roundedMidi % 12) + 12) % 12
        let octave = (roundedMidi / 12) - 1
        
        return DetectedNote(
            name: noteNames[noteIndex],
            octave: octave,
            frequency: frequency,
            cents: cents,
            midi: roundedMidi
        )
    }
    
    /// Pozice na osnově (pro grand staff). 0 = střední C (C4), kladné nahoru.
    static func staffPosition(midi: Int) -> Double {
        // C4 = MIDI 60 → position 0
        return Double(midi - 60) / 2.0   // půltóny → diatonické kroky (přibližně)
    }
}
