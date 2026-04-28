import Foundation

/// Represents a single 10ms bin of telemetry data from the N1Fusion Link.
struct SpikePacket: Decodable {
    /// The exact simulator event loop time (in seconds) when this packet was generated.
    let timestamp: Double
    
    /// The actual intended 2D movement vector [vx, vy] at this point in time.
    let kinematics: [Double]
    
    /// A flat array containing the IDs of the neurons that fired during this 10ms bin.
    let spikes: [Int]
}
