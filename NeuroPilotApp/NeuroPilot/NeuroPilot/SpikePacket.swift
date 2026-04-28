import Foundation

/// A single packet of neural data received from the NeuroPilot simulator.
/// Each packet represents a 10ms bin of activity from the motor cortex,
/// following the JSON schema defined in Phase 1 of the N1Fusion Link.
struct SpikePacket: Codable, Identifiable {
    /// Unique identifier for SwiftUI list rendering and tracking.
    /// Not present in the simulator JSON schema; generated locally upon decoding.
    let id = UUID()
    
    /// The exact simulator event loop time (in seconds) when this packet was generated.
    /// Used downstream to measure end-to-end system latency.
    let timestamp: Double
    
    /// The actual intended 2D movement vector [vx, vy] at this point in time.
    /// This represents the "ground truth" movement intention following a Figure-8 trajectory.
    let kinematics: [Double]
    
    /// A flat array containing the IDs of the neurons that fired during this 10ms bin.
    /// If a highly active neuron fires multiple times in the bin, its ID appears multiple times.
    /// This accurately mimics raw threshold crossings detected by a physical microelectrode array.
    let spikes: [Int]
    
    // MARK: - Computed Helpers
    
    /// Helper to access horizontal velocity (vx).
    var vx: Double {
        kinematics.count > 0 ? kinematics[0] : 0.0
    }
    
    /// Helper to access vertical velocity (vy).
    var vy: Double {
        kinematics.count > 1 ? kinematics[1] : 0.0
    }
    
    /// Maps the flat list of spike IDs to a dictionary of counts per neuron.
    /// Useful for decoding algorithms that operate on bin-wise firing rates/counts.
    var spikeCounts: [Int: Int] {
        return spikes.reduce(into: [:]) { (counts, neuronID) in
            counts[neuronID, default: 0] += 1
        }
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case kinematics
        case spikes
    }
}
