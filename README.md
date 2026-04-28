# NeuroPilot

A native macOS application that demonstrates real-time brain-computer interface control.  
Simulated neural signals are decoded into cursor movement, enabling a "mind-controlled" computer interface — built with the same engineering principles used by clinical BCI systems.

**Motivation**: Showcase the full pipeline of a BCI application, from neural signal simulation to low‑latency decoding and user‑centric UI design, for the Neuralink BCI Applications team.

## Architecture Overview

- **Neural Simulator** (Python) – generates synthetic motor cortex spike trains over TCP  
- **Native macOS App** (Swift + SwiftUI) – receives spikes, runs decoder, drives UI  
- **Decoder** – Population Vector (v1) / Kalman Filter (v2), optimized with Accelerate  
- **Metrics & Web Dashboard** (future) – session logging and performance visualization  

## Quick Start (once built)

1. Start the simulator: `python simulator.py`
2. Launch the macOS app
3. Run calibration, then control the cursor

## Tech Stack

| Component       | Technology              |
|-----------------|-------------------------|
| Neural Sim      | Python 3.10+ (NumPy, asyncio) |
| Desktop App     | Swift 5.9+, SwiftUI, Combine, Network framework |
| Decoder         | Swift + Accelerate framework |
| Dashboard (opt) | React + Node.js + SQLite |

## Repository Structure (planned)

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
