use n1_fusion::{DeltaEncoder, BrainwirePacket};
use std::io::{Write};
use std::fs::File;

fn main() -> std::io::Result<()> {
    println!("🧠 NeuroPilot .brainwire Reference Encoder");
    
    // Simulate some neural data (sine wave + noise)
    let n_samples = 1000;
    let mut raw_data = Vec::with_capacity(n_samples);
    for i in 0..n_samples {
        let val = (i as f64 * 0.1).sin() * 100.0 + (rand_val() * 5.0);
        raw_data.push(val as i32);
    }

    println!("📊 Processing {} samples...", n_samples);

    let mut encoder = DeltaEncoder::new();
    let mut deltas = Vec::new();
    
    for &sample in &raw_data {
        deltas.push(encoder.encode(sample));
    }

    let packet = BrainwirePacket {
        channel_id: 1,
        timestamp: 123456789,
        deltas,
        bit_width: 8, // Reference target
    };

    let serialized = packet.serialize();
    let filename = "output.brainwire";
    let mut file = File::create(filename)?;
    file.write_all(&serialized)?;

    println!("✅ Successfully encoded data to {}", filename);
    println!("📈 Raw size: {} bytes", n_samples * 4);
    println!("📉 Compressed size: {} bytes", serialized.len());
    
    let ratio = (serialized.len() as f64 / (n_samples * 4) as f64) * 100.0;
    println!("⚡ Compression ratio: {:.2}%", ratio);

    Ok(())
}

fn rand_val() -> f64 {
    // Simple deterministic pseudo-random for reference
    static mut SEED: u32 = 42;
    unsafe {
        SEED = SEED.wrapping_mul(1103515245).wrapping_add(12345);
        (SEED % 100) as f64 / 100.0
    }
}
