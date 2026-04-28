# NeuroPilot

A high-performance, open-source framework for building bi-directional brain-computer interface (BCI) applications. 

*Developed by [Aaron Guo](https://www.linkedin.com/in/guo-aaron/) and [Lily Hwang](https://www.linkedin.com/in/lilyhjs/)*

## The Problem: Digital Isolation & The BCI Bottleneck
When individuals suffer from severe paralysis (due to ALS, spinal cord injuries, or stroke), their physical bodies can no longer move, but their brains—specifically the motor cortex—are still perfectly capable of intending to move. They become physically and digitally isolated.

Implanting a microelectrode array into the brain intercepts those movement intentions as a massive stream of raw electrical noise (spikes). **The core engineering challenge** is turning that chaotic waterfall of data into a smooth, instantaneous mouse click on a screen. If the software pipeline lags, drops packets, or uses too much memory, the UI stutters and the user experience is ruined.

## How NeuroPilot Solves It
NeuroPilot is designed as a foundational, open-source framework for the BCI engineering community. Rather than a closed ecosystem, it is built to easily plug into and integrate with existing brain telemetry hardware streams (from any microelectrode array) and provides highly modular logic for decoding algorithms and clinical dashboards.

By engineering this from first principles, it proves that we can achieve the low-latency concurrency required to decode raw data fast enough to provide a seamless user experience. Our mission is to provide a robust, drop-in architecture that can be deployed in clinical environments to help restore movement to the paralyzed—enabling users to control computers, phones, and digital agents with their minds at the speed of thought.

**Built for the Clinic**: Designed to support fast iteration cycles, NeuroPilot empowers engineering teams to rapidly swap out modular dashboards or decoding logic. This allows researchers to work closely with clinical trial participants, test novel computer user interfaces, and refine brain control experiences based on direct user feedback.

## Architecture Overview

NeuroPilot is dedicated to delivering elegant, maintainable, performant, and reliable user-facing software. The architecture spans several cross-functional domains:

- **`N1Fusion Link` (Simulated Hardware Bridge)**: A Rust library that mimics a compressed telemetry stream over TCP/BLE, serving as the project's test harness.
- **`NeuroPilot Desktop` (Low-Latency Mac/iOS App)**: A native Swift package that ingests telemetry streams and renders a zero-latency cursor via a custom Apple Metal pipeline.
- **`NeuroPilot Core` (C++ Decoder Engine)**: The core mathematical engine (Kalman Filter) written in C++ for maximum performance, exposed via `pybind11` for Python training and bridged to Swift for on-device inference.
- **`NeuroPilot Assess` (Clinical Calibration)**: Standardized psychomotor tasks (Webgrid clone) built in Swift to gather training data and assess decoder performance in Bits Per Second.
- **`NeuroPilot Cloud` (Clinical Dashboard)**: A modern full-stack web dashboard (FastAPI + React) backed by PostgreSQL and TimescaleDB for remote session logging and clinical review.

## Documentation & Resources

For a deep dive into the project's design, terminology, and future plans, please refer to our dedicated documentation:

- 🧠 **[BCI Glossary & Domain Knowledge](docs/bci_glossary.md)**: A beginner-friendly guide to the neuroscience, hardware, and algorithmic terminology used in this project (e.g., motor cortex, spikes, Kalman filters).
- 🏢 **[Industry Tech Stack Comparison](docs/industry_comparison.md)**: A cross-industry breakdown of how major BCI companies (Neuralink, Blackrock, Synchron) architect their software pipelines.
- ⚙️ **[Architecture & Data Specs](docs/architecture.md)**: Details the high-level data flow, network topology, and the exact JSON payload schema streaming from the simulator.
- 🗺️ **[Project Roadmap](docs/roadmap.md)**: A detailed, step-by-step 5-phase master plan outlining upcoming milestones, features, and the current state of the end-to-end system.
- 📚 **[References & Prior Art](docs/references.md)**: A curated directory of open-source BCI research frameworks, hardware interfaces, and decoding algorithms.

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
| N1Fusion Link   | Rust, Python 3.10+ (asyncio) |
| Desktop App     | Swift 5.9+, SwiftUI, Apple Metal |
| Core Decoder    | C++, pybind11 |
| Assess / Cloud  | Python (FastAPI), React (TypeScript), PostgreSQL, TimescaleDB |
