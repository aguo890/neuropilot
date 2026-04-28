# Architecture Overview

`N1Fusion Link` (Rust) --[BLE/TCP JSON]--> `NeuroPilot Desktop` (Swift) --[`NeuroPilot Core` (C++)]--> Cursor/UI (Metal)

## High-Level Data Flow

1. **`N1Fusion Link` (Data Ingress & Simulation)**: Written in Rust. It generates synthetic motor cortex spike trains or parses raw hardware telemetry, acting as a safety-critical parser and server that emits data packets at 100 Hz.
2. **`NeuroPilot Desktop` (Native Client)**: Native macOS/iOS app built with Swift. It connects to the N1Fusion Link, manages the Bluetooth/TCP connection, and handles high-performance zero-latency UI rendering via Apple Metal.
3. **`NeuroPilot Core` (Decoder Engine)**: Written in C++. Transforms the incoming neural spikes into continuous movement commands using mathematical models (e.g. Kalman Filter). Exposed to Swift via a bridging header.
4. **`NeuroPilot Assess` & `Cloud`**: Swift-based clinical tasks (Assess) generate session logs which are uploaded to a React (TypeScript) and FastAPI (Python) dashboard (Cloud) for remote metrics tracking.

## Data Stream Schema

Each newline-delimited JSON packet streaming from the `N1Fusion Link` represents a 10ms simulation bin.

**Example Payload:**
```json
{"timestamp": 83262.479885916, "kinematics": [-0.7511403567705126, 0.9917193961455366], "spikes": [2, 5, 19, 20, 31, 46, 49, 57, 66, 66, 69, 80, 90, 91, 94]}
```

**Field Dictionary:**
- `timestamp` *(float)*: The exact simulator event loop time (in seconds) when this packet was generated. Used downstream to measure end-to-end system latency.
- `kinematics` *(array of floats)*: The actual intended 2D movement vector `[vx, vy]` at this point in time (following a Figure-8 trajectory). This represents the "ground truth" movement intention. Downstream clinical dashboards use this alongside the decoded movement to calculate decoding error metrics.
- `spikes` *(array of ints)*: A flat array containing the IDs of the neurons that fired during this 10ms bin. If a highly active neuron (like ID `66`) fires twice in the bin, its ID appears twice. This accurately mimics raw threshold crossings detected by a physical microelectrode array.

## Repository Structure (Planned)

```text
neuropilot/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── bci_glossary.md
│   ├── industry_comparison.md
│   └── roadmap.md
├── n1fusion_link/        (Phase 1: Rust Ingress/Simulator)
├── neuropilot_desktop/   (Phase 2: Swift App & Metal UI)
├── neuropilot_core/      (Phase 3: C++ Decoder Engine)
├── neuropilot_assess/    (Phase 4: Clinical Calibration Tasks)
└── neuropilot_cloud/     (Phase 5: FastAPI/React Dashboard)
```
