import Foundation
import SwiftUI
import Combine

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
    
    // Source selection
    @Published var source: TelemetrySource = .tcp
    
    // Concrete clients
    let tcpClient = TCPTelemetryClient()
    let bluetoothManager = BluetoothManager()
    
    private var cancellables = Set<AnyCancellable>()
    private let maxHistory = 100
    
    init() {
        // Setup packet handlers for both
        tcpClient.onPacketReceived = { [weak self] packet in
            self?.handlePacket(packet)
        }
        bluetoothManager.onPacketReceived = { [weak self] packet in
            self?.handlePacket(packet)
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
    
    private func handlePacket(_ packet: SpikePacket) {
        currentKinematics = packet.kinematics
        spikeHistory.append(packet.spikes)
        if spikeHistory.count > maxHistory {
            spikeHistory.removeFirst()
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
