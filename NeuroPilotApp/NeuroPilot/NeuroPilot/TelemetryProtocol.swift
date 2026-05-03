import Foundation
import Combine

/// Common states for telemetry connections.
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// Abstract protocol for neural telemetry sources (BLE, TCP, etc.)
protocol TelemetryProvider: AnyObject {
    var status: ConnectionStatus { get }
    var packetsPerSecond: Int { get }
    var onPacketsReceived: (([SpikePacket]) -> Void)? { get set }
    
    func connect()
    func disconnect()
}
