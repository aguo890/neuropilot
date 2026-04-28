# NeuroPilot

A high-performance, open-source framework for building bi-directional brain-computer interface (BCI) applications. 

## The Problem: Digital Isolation & The BCI Bottleneck
When individuals suffer from severe paralysis (due to ALS, spinal cord injuries, or stroke), their physical bodies can no longer move, but their brains—specifically the motor cortex—are still perfectly capable of intending to move. They become physically and digitally isolated.

Implanting a microelectrode array into the brain intercepts those movement intentions as a massive stream of raw electrical noise (spikes). **The core engineering challenge** is turning that chaotic waterfall of data into a smooth, instantaneous mouse click on a screen. If the software pipeline lags, drops packets, or uses too much memory, the UI stutters and the user experience is ruined.

## How NeuroPilot Solves It
NeuroPilot is designed as a foundational, open-source framework for the BCI engineering community. Rather than a closed ecosystem, it is built to easily plug into and integrate with existing brain telemetry hardware streams (from any microelectrode array) and provides highly modular logic for decoding algorithms and clinical dashboards.

By engineering this from first principles, it proves that we can achieve the low-latency concurrency required to decode raw data fast enough to provide a seamless user experience. Our mission is to provide a robust, drop-in architecture that can be deployed in clinical environments to help restore movement to the paralyzed—enabling users to control computers, phones, and digital agents with their minds at the speed of thought.

**Built for the Clinic**: Designed to support fast iteration cycles, NeuroPilot empowers engineering teams to rapidly swap out modular dashboards or decoding logic. This allows researchers to work closely with clinical trial participants, test novel computer user interfaces, and refine brain control experiences based on direct user feedback.

## Architecture Overview

NeuroPilot is dedicated to delivering elegant, maintainable, performant, and reliable user-facing software. The architecture spans several cross-functional domains:

- **Neural Simulator (Python)**: A highly concurrent `asyncio` TCP server that generates synthetic motor cortex spike trains via a robust mathematical population model.
- **Native macOS/iOS App (Swift + SwiftUI)**: A native application that delivers exceptional user experiences centered around brain control. Employs low-latency networking, concurrent programming, and strict memory management to receive continuous spike streams in real-time.
- **Signal Decoder**: Designs and implements algorithms to decode brain activity (Population Vector / Kalman Filter) optimized natively via Apple's Accelerate framework.
- **Clinical Dashboard (Future)**: Full-stack metrics and session logging to track clinical tasks, validate software systems, and measure user performance metrics.

## Documentation & Resources

For a deep dive into the project's design, terminology, and future plans, please refer to our dedicated documentation:

- 🧠 **[BCI Glossary & Domain Knowledge](docs/bci_glossary.md)**: A beginner-friendly guide to the neuroscience, hardware, and algorithmic terminology used in this project (e.g., motor cortex, spikes, Kalman filters).
- ⚙️ **[Architecture & Data Specs](docs/architecture.md)**: Details the high-level data flow, network topology, and the exact JSON payload schema streaming from the simulator.
- 🗺️ **[Project Roadmap](docs/roadmap.md)**: A detailed, step-by-step 8-phase master plan outlining upcoming milestones, features, and the current state of the end-to-end system.

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

## Tech Stack

| Component       | Technology              |
|-----------------|-------------------------|
| Neural Sim      | Python 3.10+ (NumPy, asyncio) |
| Native Client   | Swift 5.9+, SwiftUI, Combine, Network framework |
| Decoder         | Swift + Accelerate framework |
| Clinical Dash   | React + Node.js + SQLite |
