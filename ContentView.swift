import SwiftUI

struct ContentView: View {
    @StateObject private var detector = PitchDetector()
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Rozpoznávání tónů klavíru")
                .font(.title2.bold())
            
            // Velká nota
            if let note = detector.currentNote {
                Text(note.displayName)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(centsColor(note.cents))
                
                Text(String(format: "%.1f Hz  •  %+.0f cent", note.frequency, note.cents))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
                Text(detector.isRunning ? "Hrajte notu…" : "Stiskněte Start")
                    .foregroundStyle(.secondary)
            }
            
            // Grand staff
            StaffView(note: detector.currentNote)
                .padding(.horizontal)
            
            // Amplituda
            ProgressView(value: Double(min(detector.amplitude * 5, 1)))
                .tint(.green)
                .padding(.horizontal, 40)
            
            // Tlačítka
            HStack(spacing: 20) {
                Button(detector.isRunning ? "Stop" : "Start") {
                    if detector.isRunning {
                        detector.stop()
                    } else {
                        detector.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            if let error = detector.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Automaticky nespouštíme – uživatel musí dát permission
        }
    }
    
    private func centsColor(_ cents: Double) -> Color {
        let absCents = abs(cents)
        if absCents < 10 { return .green }
        if absCents < 30 { return .orange }
        return .red
    }
}

#Preview {
    ContentView()
}
