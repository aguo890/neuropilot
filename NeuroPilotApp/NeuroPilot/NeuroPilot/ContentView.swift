import SwiftUI

struct ContentView: View {
    @StateObject private var pipeline = Pipeline()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("NeuroPilot Desktop")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(pipeline.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(pipeline.isConnected ? "Connected" : "Disconnected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer().frame(width: 20)
                
                Button(action: {
                    if pipeline.isConnected {
                        pipeline.disconnect()
                    } else {
                        pipeline.connect()
                    }
                }) {
                    Text(pipeline.isConnected ? "Disconnect" : "Connect")
                        .frame(width: 80)
                }
                .buttonStyle(.borderedProminent)
                .tint(pipeline.isConnected ? .red : .blue)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Visualization Area
            GeometryReader { geometry in
                ZStack {
                    Color(NSColor.controlBackgroundColor)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Draw grid/crosshairs
                    Path { path in
                        let midX = geometry.size.width / 2
                        let midY = geometry.size.height / 2
                        path.move(to: CGPoint(x: midX, y: 0))
                        path.addLine(to: CGPoint(x: midX, y: geometry.size.height))
                        path.move(to: CGPoint(x: 0, y: midY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                    }
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    
                    if let packet = pipeline.latestPacket, packet.kinematics.count >= 2 {
                        // Kinematics are bounded [-1, 1], map to screen center
                        let vx = packet.kinematics[0]
                        let vy = packet.kinematics[1]
                        
                        let centerX = geometry.size.width / 2
                        let centerY = geometry.size.height / 2
                        
                        // Scale factors: move 40% of the screen width/height to leave margins
                        let scaleX = geometry.size.width * 0.4
                        let scaleY = geometry.size.height * 0.4
                        
                        let cursorX = centerX + (vx * scaleX)
                        let cursorY = centerY - (vy * scaleY) // Invert Y so positive is up
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .shadow(color: .blue.opacity(0.5), radius: 5)
                            .position(x: cursorX, y: cursorY)
                            // A subtle animation to smooth the 10ms updates, though 100Hz is smooth enough usually
                            .animation(.linear(duration: 0.01), value: packet.timestamp)
                    } else if pipeline.isConnected {
                        Text("Waiting for telemetry...")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Click Connect to start pipeline")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
