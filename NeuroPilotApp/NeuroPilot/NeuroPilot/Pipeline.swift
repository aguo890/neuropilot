import Foundation
import SwiftUI

@MainActor
class Pipeline: ObservableObject, TelemetryClientDelegate {
    @Published var isConnected: Bool = false
    @Published var latestPacket: SpikePacket?
    @Published var connectionError: String?
    
    private let client = TelemetryClient()
    
    init() {
        client.delegate = self
    }
    
    func connect() {
        connectionError = nil
        client.connect()
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    nonisolated func telemetryClient(_ client: TelemetryClient, didChangeState isConnected: Bool) {
        Task { @MainActor in
            self.isConnected = isConnected
            if !isConnected {
                // If it disconnected and we didn't initiate it, might be an error or just closed
                // We could set an error message if needed, but for now just update the status
            }
        }
    }
    
    nonisolated func telemetryClient(_ client: TelemetryClient, didReceive packet: SpikePacket) {
        Task { @MainActor in
            self.latestPacket = packet
        }
    }
}
