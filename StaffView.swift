import SwiftUI

struct StaffView: View {
    let note: DetectedNote?
    
    private let lineSpacing: CGFloat = 12
    private let staffHeight: CGFloat = 12 * 4   // 5 linek
    
    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let trebleTop = midY - staffHeight - 30
            let bassTop = midY + 30
            
            // Treble staff
            drawStaff(context: context, top: trebleTop, width: size.width)
            drawClef(context: context, isTreble: true, x: 20, top: trebleTop)
            
            // Bass staff
            drawStaff(context: context, top: bassTop, width: size.width)
            drawClef(context: context, isTreble: false, x: 20, top: bassTop)
            
            // Note
            if let note {
                drawNote(context: context, note: note, size: size, trebleTop: trebleTop, bassTop: bassTop)
            }
        }
        .frame(height: 220)
        .background(Color(.systemBackground))
    }
    
    private func drawStaff(context: GraphicsContext, top: CGFloat, width: CGFloat) {
        for i in 0..<5 {
            let y = top + CGFloat(i) * lineSpacing
            var path = Path()
            path.move(to: CGPoint(x: 10, y: y))
            path.addLine(to: CGPoint(x: width - 10, y: y))
            context.stroke(path, with: .color(.primary), lineWidth: 1.5)
        }
    }
    
    private func drawClef(context: GraphicsContext, isTreble: Bool, x: CGFloat, top: CGFloat) {
        let text = Text(isTreble ? "𝄞" : "𝄢")
            .font(.system(size: isTreble ? 48 : 42))
        context.draw(text, at: CGPoint(x: x, y: top + (isTreble ? 28 : 22)))
    }
    
    private func drawNote(context: GraphicsContext, note: DetectedNote, size: CGSize, trebleTop: CGFloat, bassTop: CGFloat) {
        let midi = note.midi
        let x = size.width * 0.55
        
        // Rozhodnutí, na kterou osnovu
        let useTreble = midi >= 60   // C4 a výš → treble (s ledger)
        let top = useTreble ? trebleTop : bassTop
        
        // Pozice: C4 = první ledger pod treble / nad bass
        // Každý diatonický krok = lineSpacing / 2
        let stepsFromC4 = Double(midi - 60) * 0.5   // přibližně (ignorujeme enharmoniku pro jednoduchost)
        let y = top + staffHeight - CGFloat(stepsFromC4) * (lineSpacing / 2) - (useTreble ? 0 : staffHeight + 60)
        
        // Ledger lines
        drawLedgerLines(context: context, y: y, top: top, x: x, width: size.width)
        
        // Note head
        let noteRect = CGRect(x: x - 8, y: y - 6, width: 16, height: 12)
        context.fill(Path(ellipseIn: noteRect), with: .color(.primary))
        
        // Stem (nahoru nebo dolů)
        let stemUp = y > top + staffHeight / 2
        var stem = Path()
        let stemX = stemUp ? x + 7 : x - 7
        stem.move(to: CGPoint(x: stemX, y: y))
        stem.addLine(to: CGPoint(x: stemX, y: y + (stemUp ? -35 : 35)))
        context.stroke(stem, with: .color(.primary), lineWidth: 1.5)
    }
    
    private func drawLedgerLines(context: GraphicsContext, y: CGFloat, top: CGFloat, x: CGFloat, width: CGFloat) {
        let staffBottom = top + staffHeight
        // Nad osnovou
        if y < top {
            var current = top - lineSpacing
            while current >= y - 2 {
                var path = Path()
                path.move(to: CGPoint(x: x - 14, y: current))
                path.addLine(to: CGPoint(x: x + 14, y: current))
                context.stroke(path, with: .color(.primary), lineWidth: 1.5)
                current -= lineSpacing
            }
        }
        // Pod osnovou
        if y > staffBottom {
            var current = staffBottom + lineSpacing
            while current <= y + 2 {
                var path = Path()
                path.move(to: CGPoint(x: x - 14, y: current))
                path.addLine(to: CGPoint(x: x + 14, y: current))
                context.stroke(path, with: .color(.primary), lineWidth: 1.5)
                current += lineSpacing
            }
        }
    }
}
