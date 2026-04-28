# Architecture Overview

Simulator (Python) --[TCP JSON]--> SwiftApp --[Decoder]--> Cursor/UI

## High-Level Data Flow

1. **Simulator (Python)**: Generates synthetic motor cortex spike trains. It runs a TCP server that emits JSON packets containing spike data at 100 Hz.
2. **SwiftApp**: Native macOS app built with Swift and SwiftUI. It connects to the simulator via TCP, reads the JSON packets, and processes the spike data.
3. **Decoder**: Transforms the incoming neural spikes into movement commands (e.g., using a Population Vector or Kalman Filter).
4. **Cursor/UI**: Updates the application interface (such as moving a cursor) based on the decoded movement commands in real-time.

## Data Stream Schema

Each newline-delimited JSON packet streaming from the Python Simulator represents a 10ms simulation bin.

**Example Payload:**
```json
{"timestamp": 83262.479885916, "kinematics": [-0.7511403567705126, 0.9917193961455366], "spikes": [2, 5, 19, 20, 31, 46, 49, 57, 66, 66, 69, 80, 90, 91, 94]}
```

**Field Dictionary:**
- `timestamp` *(float)*: The exact simulator event loop time (in seconds) when this packet was generated. Used downstream to measure end-to-end system latency.
- `kinematics` *(array of floats)*: The actual intended 2D movement vector `[vx, vy]` at this point in time (following a Figure-8 trajectory). This represents the "ground truth" movement intention. Downstream clinical dashboards use this alongside the decoded movement to calculate decoding error metrics.
- `spikes` *(array of ints)*: A flat array containing the IDs of the neurons that fired during this 10ms bin. If a highly active neuron (like ID `66`) fires twice in the bin, its ID appears twice. This accurately mimics raw threshold crossings detected by a physical microelectrode array.
