# Architecture Overview

Simulator (Python) --[TCP JSON]--> SwiftApp --[Decoder]--> Cursor/UI

## High-Level Data Flow

1. **Simulator (Python)**: Generates synthetic motor cortex spike trains. It runs a TCP server that emits JSON packets containing spike data at 100 Hz.
2. **SwiftApp**: Native macOS app built with Swift and SwiftUI. It connects to the simulator via TCP, reads the JSON packets, and processes the spike data.
3. **Decoder**: Transforms the incoming neural spikes into movement commands (e.g., using a Population Vector or Kalman Filter).
4. **Cursor/UI**: Updates the application interface (such as moving a cursor) based on the decoded movement commands in real-time.
