/// Adaptive Delta Encoder for NeuroPilot .brainwire stream.
/// This module provides the reference implementation for compressing 
/// raw neural electrode voltage readings.

pub struct DeltaEncoder {
    last_value: i32,
    adaptive_step: u32,
}

impl DeltaEncoder {
    pub fn new() -> Self {
        Self {
            last_value: 0,
            adaptive_step: 4, // Start with 4 bits for deltas
        }
    }

    /// Resets the encoder state
    pub fn reset(&mut self) {
        self.last_value = 0;
        self.adaptive_step = 4;
    }

    /// Encodes a single sample and returns the delta.
    /// In a real implementation, this would also handle bit-packing.
    pub fn encode(&mut self, current_value: i32) -> i32 {
        let delta = current_value - self.last_value;
        self.last_value = current_value;
        
        // Adaptive logic: if delta is too large for current step, increase step
        // This is a simplified reference model.
        let abs_delta = delta.abs();
        if abs_delta > (1 << (self.adaptive_step - 1)) - 1 {
            self.adaptive_step = (self.adaptive_step + 1).min(16);
        } else if abs_delta < (1 << (self.adaptive_step - 2)) && self.adaptive_step > 2 {
            self.adaptive_step -= 1;
        }

        delta
    }

    /// Decodes a delta back into the absolute value
    pub fn decode(&mut self, delta: i32) -> i32 {
        let current_value = self.last_value + delta;
        self.last_value = current_value;
        current_value
    }
}

pub struct BrainwirePacket {
    pub channel_id: u16,
    pub timestamp: u64,
    pub deltas: Vec<i32>,
    pub bit_width: u8,
}

impl BrainwirePacket {
    /// Serializes the packet into a byte buffer (mock implementation)
    pub fn serialize(&self) -> Vec<u8> {
        let mut buffer = Vec::new();
        buffer.extend_from_slice(&self.channel_id.to_be_bytes());
        buffer.extend_from_slice(&self.timestamp.to_be_bytes());
        buffer.push(self.bit_width);
        
        // In a real implementation, we would bit-pack these deltas.
        // For the reference encoder, we'll store them as variable-length i32 for simplicity
        // in this initial version, but flag the intended bit_width.
        for &delta in &self.deltas {
            buffer.extend_from_slice(&delta.to_be_bytes());
        }
        
        buffer
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_delta_encoding_roundtrip() {
        let mut encoder = DeltaEncoder::new();
        let mut decoder = DeltaEncoder::new();
        
        let samples = vec![10, 15, 12, 100, 105, 95, 20, 10];
        let mut encoded = Vec::new();
        
        for &s in &samples {
            encoded.push(encoder.encode(s));
        }
        
        let mut decoded = Vec::new();
        for &e in &encoded {
            decoded.push(decoder.decode(e));
        }
        
        assert_eq!(samples, decoded);
    }

    #[test]
    fn test_adaptation() {
        let mut encoder = DeltaEncoder::new();
        
        // Small changes: step should stay low or decrease
        for i in 1..5 {
            encoder.encode(i);
        }
        let mid_step = encoder.adaptive_step;
        
        // Large jump: step MUST increase
        encoder.encode(1000);
        assert!(encoder.adaptive_step > mid_step, "Step should increase on large delta. Mid: {}, New: {}", mid_step, encoder.adaptive_step);
    }
}
