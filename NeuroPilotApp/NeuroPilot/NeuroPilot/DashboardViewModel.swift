import Foundation
import SwiftUI
import Combine
import AVFoundation

enum TelemetrySource {
    case tcp
    case bluetooth
}

class DashboardViewModel: ObservableObject {
    // Current connection state (aggregated from active client)
    @Published var status: ConnectionStatus = .disconnected
    @Published var packetsPerSecond: Int = 0
    
    // Data stream metrics
    @Published var spikeHistory: [[Int]] = []
    @Published var currentKinematics: [Double] = [0, 0]
    @Published var confidence: Double = 1.0
    @Published var isArtifactDetected: Bool = false
    @Published var cursorPoint: CGPoint = .zero
    
    // Source selection
    @Published var source: TelemetrySource = .tcp
    
    // Concrete clients
    let tcpClient = TCPTelemetryClient()
    let bluetoothManager = BluetoothManager()
    
    private var cancellables = Set<AnyCancellable>()
    private let maxHistory = 100
    
    init() {
        // Setup packet handlers for both
        tcpClient.onPacketsReceived = { [weak self] packets in
            self?.handleBatch(packets)
        }
        bluetoothManager.onPacketsReceived = { [weak self] packets in
            self?.handleBatch(packets)
        }
        
        // Sync status and metrics based on active source
        $source
            .sink { [weak self] newSource in
                self?.setupSubscriptions(for: newSource)
            }
            .store(in: &cancellables)
    }
    
    private func setupSubscriptions(for source: TelemetrySource) {
        cancellables.removeAll()
        
        // Re-add the source observer
        $source
            .sink { [weak self] newSource in
                if newSource != source { self?.setupSubscriptions(for: newSource) }
            }
            .store(in: &cancellables)
        
        switch source {
        case .tcp:
            tcpClient.$status.assign(to: &$status)
            tcpClient.$packetsPerSecond.assign(to: &$packetsPerSecond)
        case .bluetooth:
            bluetoothManager.$status.assign(to: &$status)
            bluetoothManager.$packetsPerSecond.assign(to: &$packetsPerSecond)
        }
    }
    
    private func handleBatch(_ packets: [SpikePacket]) {
        guard let lastPacket = packets.last else { return }
        
        // Update global state
        self.confidence = lastPacket.confidence
        self.isArtifactDetected = packets.contains(where: { $0.isArtifact })
        
        // ARTIFACT SHIELD: If noise is detected, "mute" the kinematics update
        if isArtifactDetected {
            SoundManager.shared.playArtifactAlert()
        } else {
            currentKinematics = lastPacket.kinematics
            // Map kinematics to normalized CGPoint for Metal with clamping to prevent out-of-bounds
            let clampedX = max(-1.0, min(1.0, currentKinematics[0]))
            let clampedY = max(-1.0, min(1.0, currentKinematics[1]))
            cursorPoint = CGPoint(x: clampedX, y: clampedY)
        }
        
        // Append spike data for visualization (rasters show noise too)
        for packet in packets {
            spikeHistory.append(packet.spikes)
        }
        
        // BIOFEEDBACK: Auditory ping based on movement magnitude
        let distance = sqrt(pow(currentKinematics[0], 2) + pow(currentKinematics[1], 2))
        SoundManager.shared.playPing(distance: distance)
        
        if spikeHistory.count > maxHistory {
            spikeHistory.removeFirst(spikeHistory.count - maxHistory)
        }
    }
    
    func toggleConnection() {
        let activeClient: any TelemetryProvider = (source == .tcp) ? tcpClient : bluetoothManager
        
        if case .connected = activeClient.status {
            activeClient.disconnect()
        } else {
            activeClient.connect()
        }
    }
}

/// Manages auditory feedback for the NeuroPilot system.
/// Uses pitch-shifted pings to help users "feel" their proximity to targets.
class SoundManager {
    static let shared = SoundManager()
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let pitchControl = AVAudioUnitTimePitch()
    
    private var audioFile: AVAudioFile?
    
    private init() {
        setupEngine()
    }
    
    private func setupEngine() {
        // Load a simple short beep/ping sound
        // For MVP, we'll try to find a system sound or just prepare the engine
        guard let url = Bundle.main.url(forResource: "ping", withExtension: "wav") else {
            print("⚠️ Sound file 'ping.wav' not found in bundle. Auditory feedback disabled.")
            return
        }
        
        do {
            audioFile = try AVAudioFile(forReading: url)
            
            engine.attach(player)
            engine.attach(pitchControl)
            
            let format = audioFile!.processingFormat
            engine.connect(player, to: pitchControl, format: format)
            engine.connect(pitchControl, to: engine.mainMixerNode, format: format)
            
            try engine.start()
        } catch {
            print("⚠️ Failed to start AVAudioEngine: \(error)")
        }
    }
    
    /// Play a ping with a pitch adjusted by the proximity to a target.
    /// - Parameter distance: Distance to target (0.0 = on target, 1.0+ = far)
    func playPing(distance: Double) {
        guard engine.isRunning, let file = audioFile else { return }
        
        // Map distance (0.0 to 2.0) to pitch (-1200 to 1200 cents)
        // Lower distance = Higher pitch
        let pitch = Float((1.0 - min(distance, 2.0)) * 1200.0)
        pitchControl.pitch = pitch
        
        if !player.isPlaying {
            player.scheduleFile(file, at: nil, completionHandler: nil)
            player.play()
        }
    }
    
    /// Play a distinct "alert" sound for artifacts.
    func playArtifactAlert() {
        // Placeholder for artifact sound logic
        print("🔊 ARTIFACT ALERT")
    }
}
