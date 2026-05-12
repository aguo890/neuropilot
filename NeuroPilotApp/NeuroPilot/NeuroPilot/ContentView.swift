import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                Section("Patient Session") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Patient ID: NP-42")
                            .font(.headline)
                        Text("Status: Active Ingress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Connection Controls") {
                    Picker("Source", selection: $viewModel.source) {
                        Label("TCP Sim", systemImage: "network").tag(TelemetrySource.tcp)
                        Label("Bluetooth", systemImage: "bolt.horizontal.fill").tag(TelemetrySource.bluetooth)
                    }
                    .pickerStyle(.menu)
                    
                    HStack {
                        StatusIndicator(status: viewModel.status)
                        Spacer()
                        if case .connecting = viewModel.status {
                            ProgressView().controlSize(.small)
                        }
                    }
                    
                    Button(action: viewModel.toggleConnection) {
                        Text(viewModel.status == .connected ? "Disconnect" : "Connect")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.status == .connected ? .red : .blue)
                    .controlSize(.large)
                }
                
                Section("Live Metrics") {
                    MetricRow(label: "Sampling Rate", value: "\(viewModel.packetsPerSecond) Hz", icon: "timer")
                    MetricRow(label: "Signal Quality", value: "98%", icon: "antenna.radiowaves.left.and.right", color: .green)
                    MetricRow(label: "Active Channels", value: "100/100", icon: "brain.head.profile")
                }
                
                Section("Decoder Engine (Phase 3)") {
                    Text("Inference Status: Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: .constant(0.5)) {
                        Text("Gain")
                    }
                    .disabled(true)
                }
            }
            .navigationTitle("NeuroPilot")
            
        } detail: {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        if case .connected = viewModel.status {
                            // Unified Dashboard View
                            RasterPlotView(history: viewModel.spikeHistory, maxHistory: 100)
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            
                            HStack(spacing: 20) {
                                // Kinematics Section
                                KinematicsCard(
                                    kinematics: viewModel.currentKinematics,
                                    confidence: $viewModel.confidence,
                                    cursorPoint: $viewModel.cursorPoint,
                                    isArtifactDetected: viewModel.isArtifactDetected
                                )
                                
                                // Real-time Vector Section
                                VectorCard(kinematics: viewModel.currentKinematics)
                            }
                        } else {
                            WaitingStateView(status: viewModel.status)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Live Neural Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            withAnimation {
                                columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
                            }
                        } label: {
                            Label("Toggle Sidebar", systemImage: "sidebar.left")
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewModel.spikeHistory.removeAll()
                        } label: {
                            Label("Reset Buffer", systemImage: "trash")
                        }
                        .disabled(viewModel.spikeHistory.isEmpty)
                    }
                    
                    ToolbarItem(placement: .status) {
                        if case .connected = viewModel.status {
                            Text("Recieving Data...")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

struct StatusIndicator: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.subheadline)
        }
    }
    
    private var color: Color {
        switch status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
    
    private var text: String {
        switch status {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .font(.subheadline)
    }
}

struct KinematicsCard: View {
    let kinematics: [Double]
    @Binding var confidence: Double
    @Binding var cursorPoint: CGPoint
    let isArtifactDetected: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Neural Cursor", systemImage: "move.3d")
                    .font(.headline)
                Spacer()
                if isArtifactDetected {
                    Label("Shield Active", systemImage: "shield.fill")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .symbolEffect(.pulse)
                }
            }
            
            GeometryReader { geo in
                ZStack {
                    // Grid
                    Path { path in
                        for i in 0...4 {
                            let x = CGFloat(i) * (geo.size.width / 4)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geo.size.height))
                            
                            let y = CGFloat(i) * (geo.size.height / 4)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                    }
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    
                    // Metal Cursor Layer
                    MetalView(cursorPosition: $cursorPoint, confidence: $confidence)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false) // Pass clicks through
                }
            }
            .frame(height: 200)
            .background(Color.black.opacity(0.02))
            .cornerRadius(12)
            
            // Confidence Bar
            HStack {
                Text("Decoder Confidence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                ProgressView(value: confidence)
                    .tint(cursorColor)
                    .controlSize(.small)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(16)
    }
    
    private var cursorColor: Color {
        if isArtifactDetected { return .red }
        return Color.interpolate(from: .red, to: .green, fraction: confidence)
    }
    
    private var cursorSize: CGFloat {
        if isArtifactDetected { return 25 }
        return 15 + CGFloat(confidence * 10)
    }
}

extension Color {
    static func interpolate(from: Color, to: Color, fraction: Double) -> Color {
        let f = CGFloat(max(0, min(1, fraction)))
        if f > 0.8 { return .green }
        if f > 0.4 { return .yellow }
        return .red
    }
}

struct VectorCard: View {
    let kinematics: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Label("Velocity Vectors", systemImage: "arrow.up.right.circle")
                .font(.headline)
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Vx").font(.caption).foregroundColor(.secondary)
                    Text("\(kinematics.count > 0 ? kinematics[0] : 0, specifier: "%.2f")")
                        .font(.title2.monospaced().bold())
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Vy").font(.caption).foregroundColor(.secondary)
                    Text("\(kinematics.count > 1 ? kinematics[1] : 0, specifier: "%.2f")")
                        .font(.title2.monospaced().bold())
                }
            }
            
            Spacer()
            
            // Magnitude Bar
            let mag = kinematics.count > 1 ? sqrt(pow(kinematics[0], 2) + pow(kinematics[1], 2)) : 0
            ProgressView("Magnitude", value: min(mag, 1.5), total: 1.5)
                .tint(.blue)
        }
        .padding()
        .frame(maxWidth: 200, maxHeight: 200)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(16)
    }
}

struct WaitingStateView: View {
    let status: ConnectionStatus
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .symbolEffect(.pulse, options: .repeating)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text(status == .connecting ? "Initializing Link..." : "Waiting for Neural Ingress")
                    .font(.title2.bold())
                
                Text(status == .connecting ? "Synchronizing with simulator clock..." : "Ensure the simulator is running with 'make run-sim' and click Connect in the sidebar.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}

#Preview {
    ContentView()
}
