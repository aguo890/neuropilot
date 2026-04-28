# NeuroPilot

A high-performance, open-source framework for building bi-directional brain-computer interface (BCI) applications. 

NeuroPilot is engineered from first principles to provide a reliable, low-latency pipeline that bridges raw neural signal telemetry with native application interfaces. Our core mission is to provide a robust software architecture that can be deployed in clinical environments to help restore movement to the paralyzed, enabling users to control computers, phones, and digital agents with their minds at the speed of thought.

**Built for the Clinic**: Designed to support fast iteration cycles, NeuroPilot empowers engineering teams to work closely with clinical trial participants to test novel computer user interfaces and rapidly refine brain control experiences based on direct user feedback.

## Architecture Overview

NeuroPilot is dedicated to delivering elegant, maintainable, performant, and reliable user-facing software. The architecture spans several cross-functional domains:

- **Neural Simulator (Python)**: A highly concurrent `asyncio` TCP server that generates synthetic motor cortex spike trains via a robust mathematical population model.
- **Native macOS/iOS App (Swift + SwiftUI)**: A native application that delivers exceptional user experiences centered around brain control. Employs low-latency networking, concurrent programming, and strict memory management to receive continuous spike streams in real-time.
- **Signal Decoder**: Designs and implements algorithms to decode brain activity (Population Vector / Kalman Filter) optimized natively via Apple's Accelerate framework.
- **Clinical Dashboard (Future)**: Full-stack metrics and session logging to track clinical tasks, validate software systems, and measure user performance metrics.

> 🧠 **New to BCIs?** Check out the [BCI Glossary & Domain Knowledge](docs/bci_glossary.md) guide to understand the terminology and neuroscience concepts used in this project.

## Project Roadmap
Please refer to [docs/roadmap.md](docs/roadmap.md) for a detailed, step-by-step 8-phase plan of the project architecture and upcoming milestones.

## Current Status: Phase 1 Complete
We have successfully implemented the **Neural Simulator MVP**. The simulator delivers a continuous, high-fidelity stream of synthetic neural spikes over a TCP socket at 100 Hz, mimicking the telemetry of a real implanted BCI device.

**Next Phase (Phase 2):** Building the native macOS app skeleton (SwiftUI) and implementing the asynchronous TCP client to receive the neural spikes and display a real-time raster plot.

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
   You will see a continuous 100 Hz stream of JSON packets.

### Data Stream Schema

Each newline-delimited JSON packet represents a 10ms simulation bin.

**Example Payload:**
```json
{"timestamp": 83262.479885916, "kinematics": [-0.7511403567705126, 0.9917193961455366], "spikes": [2, 5, 19, 20, 31, 46, 49, 57, 66, 66, 69, 80, 90, 91, 94]}
```

**Field Dictionary:**
- `timestamp` *(float)*: The exact simulator event loop time (in seconds) when this packet was generated. Used downstream to measure end-to-end system latency.
- `kinematics` *(array of floats)*: The actual intended 2D movement vector `[vx, vy]` at this point in time (following a Figure-8 trajectory). This represents the "ground truth" movement intention. Downstream clinical dashboards use this alongside the decoded movement to calculate decoding error metrics.
- `spikes` *(array of ints)*: A flat array containing the IDs of the neurons that fired during this 10ms bin. If a highly active neuron (like ID `66`) fires twice in the bin, its ID appears twice. This accurately mimics raw threshold crossings detected by a physical microelectrode array.

## Tech Stack

| Component       | Technology              |
|-----------------|-------------------------|
| Neural Sim      | Python 3.10+ (NumPy, asyncio) |
| Native Client   | Swift 5.9+, SwiftUI, Combine, Network framework |
| Decoder         | Swift + Accelerate framework |
| Clinical Dash   | React + Node.js + SQLite |

## Repository Structure (Planned)

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
│   ├── NeuroPilot.xcodeproj
│   └── NeuroPilot/
│       ├── AppDelegate.swift
│       ├── ContentView.swift
│       ├── SpikeReceiver.swift
│       ├── Decoder/
│       └── UI/
└── dashboard/ (future)
```
