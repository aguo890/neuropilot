import SwiftUI

struct RasterPlotView: View {
    let history: [[Int]] // Array of spike ID lists
    let maxNeurons: Int = 100
    let maxHistory: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Neural Raster", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                Text("\(maxNeurons) Channels")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            Canvas { context, size in
                let cellWidth = size.width / CGFloat(maxHistory)
                let cellHeight = size.height / CGFloat(maxNeurons)
                
                // Draw Background Glassmorphism Grid
                let path = Path(CGRect(origin: .zero, size: size))
                context.fill(path, with: .color(Color(NSColor.windowBackgroundColor).opacity(0.5)))
                
                // Horizontal grid lines (every 20 neurons)
                for i in 0...5 {
                    let y = CGFloat(i) * (size.height / 5)
                    var linePath = Path()
                    linePath.move(to: CGPoint(x: 0, y: y))
                    linePath.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(linePath, with: .color(.gray.opacity(0.1)), lineWidth: 0.5)
                }
                
                // Vertical grid lines (every quarter of history)
                for i in 0...4 {
                    let x = CGFloat(i) * (size.width / 4)
                    var linePath = Path()
                    linePath.move(to: CGPoint(x: x, y: 0))
                    linePath.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(linePath, with: .color(.gray.opacity(0.1)), lineWidth: 0.5)
                }
                
                // Draw Spikes
                for (timeIndex, spikes) in history.enumerated() {
                    for neuronId in spikes {
                        let x = CGFloat(timeIndex) * cellWidth
                        let y = size.height - (CGFloat(neuronId) * cellHeight)
                        
                        let rect = CGRect(x: x, y: y, width: max(1.5, cellWidth), height: max(1.5, cellHeight))
                        
                        // Add a subtle glow effect to spikes
                        context.addFilter(.shadow(color: .green.opacity(0.5), radius: 1, x: 0, y: 0))
                        context.fill(Path(rect), with: .color(.green))
                    }
                }
            }
            .frame(minHeight: 250)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

#Preview {
    RasterPlotView(history: [[1, 5, 10], [2, 6, 11], [3, 7, 90]], maxHistory: 100)
        .padding()
}
