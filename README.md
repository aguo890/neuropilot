# NeuroPilot

A native macOS application that demonstrates real-time brain-computer interface control.  
Simulated neural signals are decoded into cursor movement, enabling a "mind-controlled" computer interface — built with the same engineering principles used by clinical BCI systems.

**Motivation**: Showcase the full pipeline of a BCI application, from neural signal simulation to low‑latency decoding and user‑centric UI design, for the Neuralink BCI Applications team.

## Architecture Overview

- **Neural Simulator** (Python) – generates synthetic motor cortex spike trains over TCP  
- **Native macOS App** (Swift + SwiftUI) – receives spikes, runs decoder, drives UI  
- **Decoder** – Population Vector (v1) / Kalman Filter (v2), optimized with Accelerate  
- **Metrics & Web Dashboard** (future) – session logging and performance visualization  

## Current Status: Phase 1 Complete
We have successfully implemented the **Neural Simulator MVP**. The simulator generates synthetic motor cortex spike trains via a mathematical cosine-tuning population model and streams the data over a TCP socket at 100 Hz.

**Next Phase (Phase 2):** Building the native macOS app skeleton (SwiftUI) and implementing the TCP client to receive the neural spikes and display a real-time raster plot.

## Quick Start (Simulator)

1. **Start the simulator:**
   ```bash
   make run-sim
   ```
2. **View the real-time data stream:**
   Open a new terminal window and connect to the TCP socket using `netcat`:
   ```bash
   nc 127.0.0.1 9000
   ```
   You will see a continuous 100 Hz stream of JSON packets containing the timestamp, simulated movement kinematics, and the resulting neural spikes.

## Tech Stack

| Component       | Technology              |
|-----------------|-------------------------|
| Neural Sim      | Python 3.10+ (NumPy, asyncio) |
| Desktop App     | Swift 5.9+, SwiftUI, Combine, Network framework |
| Decoder         | Swift + Accelerate framework |
| Dashboard (opt) | React + Node.js + SQLite |

## Repository Structure (planned)

```text
neuropilot/
├── README.md
├── docs/
│   ├── architecture.md
│   └── roadmap.md
├── simulator/
│   ├── main.py
│   ├── neural_population.py
│   └── tcp_server.py
├── NeuroPilotApp/
│   ├── NeuroPilotApp.xcodeproj
│   └── NeuroPilotApp/
│       ├── AppDelegate.swift
│       ├── ContentView.swift
│       ├── SpikeReceiver.swift
│       ├── Decoder/
│       └── UI/
└── dashboard/ (future)
```
