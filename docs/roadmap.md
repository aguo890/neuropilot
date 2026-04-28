# 🗺️ NeuroPilot Project Roadmap

Welcome to the NeuroPilot Roadmap! This document outlines our high-level vision, current milestones, and the step-by-step technical implementation plan. We iterate fast and update this roadmap constantly.

### Status Legend
- 🟢 **Completed**
- 🟡 **In Progress**
- ⚪ **Planned**

---

## 🎯 High-Level Milestones

| Status | Phase | Milestone | Description |
|--------|-------|-----------|-------------|
| 🟢 | **Phase 0** | Project Initialization | Foundational repo, dev environment, and SwiftUI skeleton. |
| 🟢 | **Phase 1** | Neural Simulator MVP | Python TCP server emitting realistic spike telemetry. |
| 🟡 | **Phase 2** | Native macOS Skeleton + TCP | Swift App receives spikes, decodes, and plots raster. |
| ⚪ | **Phase 3** | Basic Decoder & Cursor | Population vector decoding to move a cursor on canvas. |
| ⚪ | **Phase 4** | Calibration & Metrics | Training routine to gather data + performance stats. |
| ⚪ | **Phase 5** | Advanced Decoder | Kalman filter implementation natively with Apple Accelerate. |
| ⚪ | **Phase 6** | UX Polish & Clinical Tasks | Target-click tasks, confidence indicators for user testing. |
| ⚪ | **Phase 7** | Full-Stack Dashboard | Web viewer for session data logging and metrics. |
| ⚪ | **Phase 8** | Simulated User Study | Quantitative metrics tracking and video demonstration. |

---

## 🛠️ Step-by-Step Technical Tasks

### 🟢 Phase 0: Project Initialization
**Goal**: Establish a pristine repository environment with all toolchains installed and documentation initialized.

- [x] **0.1 Create Git Repository**: Initialize, add `.gitignore`, and set up CI/CD `Makefile`.
- [x] **0.2 Directory Structure**: Scaffold `simulator/`, `NeuroPilotApp/`, and `docs/`.
- [x] **0.3 Development Environment**: Ensure Python 3.10+ and Xcode 15+ toolchains.
- [x] **0.4 Initialize SwiftUI App**: Clean build of native macOS App (SwiftUI, no Core Data).
- [x] **0.5 Write Documentation**: Scaffold `architecture.md`, `roadmap.md`, and `README.md`.

### 🟢 Phase 1: Neural Simulator MVP
**Goal**: A highly concurrent Python server streaming synthetic motor cortex spike data over TCP at 100 Hz.

- [x] **1.1 Neuron Population Model**: Build `MotorCortexSimulator` (N=100) using Cosine-Tuning math to map 2D movement vectors to firing rates.
- [x] **1.2 Movement Trajectory**: Implement a dynamic Figure-8 kinematic path generator.
- [x] **1.3 TCP Server**: Use `asyncio` to stream JSON packets containing spikes, kinematics, and timestamps at 100 Hz.
- [x] **1.4 Test Connectivity**: Verify simulator stream independently via `netcat`.

### 🟡 Phase 2: Native Mac App Skeleton + TCP Client
**Goal**: The Swift application connects to the simulator, receives spikes, and displays a live raster plot as proof of data flow.

- [ ] **2.1 TCP Client (Swift)**: Use `NWConnection` (Network framework) to connect to `localhost:9000`.
- [ ] **2.2 Data Model**: Define `SpikePacket` and parse the incoming JSON stream.
- [ ] **2.3 Raster View**: Build a high-performance `TimelineView` + `Canvas` to plot spikes in real-time (20+ Hz refresh rate).
- [ ] **2.4 E2E Testing**: Start simulator, run app, and verify visual raster syncs with network packets.
- [ ] **2.5 Basic Layout**: Scaffold `ContentView.swift` with a left pane (Raster), right pane (Cursor Canvas), and bottom Status Bar.

*(Phases 3-8 task breakdowns will be expanded as we approach them.)*
