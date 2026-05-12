# 🗺️ NeuroPilot Project Roadmap

Welcome to the NeuroPilot Roadmap! This document outlines our high-level vision, current milestones, and the step-by-step technical implementation plan. We iterate fast and update this roadmap constantly.

### Status Legend
- 🟢 **Completed**
- 🟡 **In Progress**
- ⚪ **Planned**

---

## 🎯 High-Level Milestones

| Status | Phase | Module Name | Description |
|--------|-------|-----------|-------------|
| 🟢 | **Phase 0** | `Project Init` | Foundational repo, dev environment, and SwiftUI skeleton. |
| 🟢 | **Phase 1** | `N1Fusion Link` | Simulated Hardware Bridge: Rust library imitating compressed 1Mbps telemetry. |
| 🟢 | **Phase 2** | `NeuroPilot Desktop` | Native Mac/iOS App: Swift package with BluetoothManager and MetalRenderer. |
| ⚪ | **Phase 3** | `NeuroPilot Core` | Core Decoder: C++ library for real-time decoding, bridged to Python and Swift. |
| ⚪ | **Phase 4** | `NeuroPilot Assess` | Clinical Calibration: Swift Webgrid game + Python offline analysis tools. |
| 🟡 | **Phase 5** | `NeuroPilot Cloud` | Clinical Dashboard: FastAPI + Premium Dashboard (Cognitive Fatigue implemented). |

---

## 🛠️ Step-by-Step Technical Tasks

### 🟢 Phase 0: Project Initialization
**Goal**: Establish a pristine repository environment with all toolchains installed and documentation initialized.

- [x] **0.1 Create Git Repository**: Initialize, add `.gitignore`, and set up CI/CD `Makefile`.
- [x] **0.2 Directory Structure**: Scaffold `simulator/`, `NeuroPilotApp/`, and `docs/`.
- [x] **0.3 Development Environment**: Ensure Python 3.10+ and Xcode 15+ toolchains.
- [x] **0.4 Initialize SwiftUI App**: Clean build of native macOS App (SwiftUI, no Core Data).
- [x] **0.5 Write Documentation**: Scaffold `architecture.md`, `roadmap.md`, and `README.md`.

### 🟢 Phase 1: `N1Fusion Link` (Simulated Hardware Bridge)
**Goal**: A Rust library that mimics the compressed N1 telemetry stream over TCP/BLE, serving as our project's test harness.

- [x] **1.1 Neuron Population Model**: Build `MotorCortexSimulator` (N=100) using Cosine-Tuning math to map 2D movement vectors to firing rates.
- [x] **1.2 Movement Trajectory**: Implement a dynamic Figure-8 kinematic path generator.
- [x] **1.3 Telemetry Stream**: Use `asyncio` to stream JSON packets containing spikes, kinematics, and timestamps at 100 Hz.
- [x] **1.4 Lossless Compression**: Implement a Rust reference encoder using adaptive delta encoding to compress raw electrode data into a 1 Mbps `.brainwire` stream.

### 🟢 Phase 2: `NeuroPilot Desktop` (Low-Latency Mac/iOS App)
**Goal**: A native Swift package that ingests the telemetry stream and renders a zero-latency cursor based on decoder output.

- [x] **2.1 Telemetry Client**: Implement `BluetoothManager` and `TCPTelemetryClient` to connect to the telemetry stream.
- [x] **2.2 Data Pipeline**: Define `SpikePacket` and telemetry protocols.
- [x] **2.3 MetalRenderer**: Build a custom Apple Metal pipeline to draw the cursor bypassing standard UI framework overhead.
- [x] **2.4 Basic Layout**: Scaffold `ContentView.swift` and `DashboardViewModel`.
- [x] **2.5 Real-time Visualization**: Implement `RasterPlotView` for spike train visualization.

### ⚪ Phase 3: `NeuroPilot Core` (C++ Decoder Engine)
**Goal**: The core mathematical engine responsible for the real-time decoding loop, written in C++ for performance.

- [ ] **3.1 C++ Kalman Filter**: Implement a 2D velocity prediction Kalman Filter in native C++.
- [ ] **3.2 Python Bindings**: Expose the C++ module via `pybind11` to allow rapid algorithm iteration using PyTorch/NumPy.
- [ ] **3.3 Swift Bridging**: Create an Objective-C++ bridging header to expose the decoder to `NeuroPilot Desktop` for on-device inference.

### ⚪ Phase 4: `NeuroPilot Assess` (Clinical Calibration Task)
**Goal**: Standardized psychomotor tasks to gather training data and assess decoder performance (Bits Per Second).

- [ ] **4.1 Webgrid Game**: Build a Swift-based configurable center-out grid task.
- [ ] **4.2 Session Logging**: Log every target onset, hit/miss, and calculated BPS score to a local JSON file.
- [ ] **4.3 Offline Analysis Tools**: Write Python scripts to read JSON logs, graph performance, and identify low-confidence clusters requiring recalibration.

### ⚪ Phase 5: `NeuroPilot Cloud` (Clinical Data Dashboard)
**Goal**: A modern full-stack web dashboard for remote session logging and clinical review.

- [/] **5.1 Database Schema**: Set up PostgreSQL with the TimescaleDB extension for time-series performance metrics.
- [x] **5.2 Cloud ETL Pipeline**: Build a FastAPI Python backend to receive and process session metrics.
- [x] **5.3 Cognitive Fatigue Dashboard**: Implement tracking for Time-to-target, Overshoot, and Bit-Rate Decay.
- [ ] **5.4 React Dashboard**: Build full interactive web frontend.
