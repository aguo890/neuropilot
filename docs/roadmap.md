# Project Roadmap (High-Level Phases)

| Phase | Name                         | Outcome                                      |
|-------|------------------------------|----------------------------------------------|
| 0     | Project Initialization       | Repo, dev environment, placeholder app       |
| 1     | Neural Simulator MVP         | Python TCP server emitting realistic spikes  |
| 2     | iOS/macOS Skeleton + TCP     | App receives spikes, plots raster            |
| 3     | Basic Decoder & Cursor       | Population vector moves cursor on canvas     |
| 4     | Calibration & Metrics        | Training routine + performance stats         |
| 5     | Advanced Decoder (Kalman)    | Kalman filter with Accelerate                |
| 6     | UX Polish & Clinical Tasks   | Target-click tasks, confidence indicators    |
| 7     | Full-Stack Dashboard         | Web viewer for session data                  |
| 8     | Simulated User Study         | Quantitative metrics, video demo             |

**Current focus**: Phases 0–2 (Foundational Setup).

---

## Phase List & Step-by-Step Tasks (Foundational Setup)

### Phase 0: Project Initialization

**Goal**: Repository ready, all toolchains installed, empty SwiftUI app compiles, documentation exists.

#### 0.1 Create Git Repository
- Initialize local git repo: `git init neuropilot`
- Create a `.gitignore` (macOS, Xcode, Python, Node)
- Make initial commit with README.md placeholder

#### 0.2 Set Up Directory Structure
- Create folders:
  - `simulator/`
  - `NeuroPilotApp/` (with default Xcode project later)
  - `docs/`
  - `dashboard/` (empty for now)
- Add `README.md` (use template above)

#### 0.3 Development Environment Checklist
- Python 3.10+ with `numpy` installed (`pip install numpy`)
- Xcode 15+ (macOS) with command line tools
- Swift 5.9+ / SwiftUI
- (Optional) Node.js for future dashboard

#### 0.4 Initialize SwiftUI App
- Open Xcode, create new macOS App (SwiftUI, no Core Data)
- Save project inside `NeuroPilotApp/` folder (so `.xcodeproj` is inside)
- Clean build and test (blank window)

#### 0.5 Write Initial Documentation
- Create `docs/architecture.md` with high-level data flow:
  ```
  Simulator (Python) --[TCP JSON]--> SwiftApp --[Decoder]--> Cursor/UI
  ```
- Create `docs/roadmap.md` (this file) for reference.
- Commit all.

---

### Phase 1: Neural Simulator MVP

**Goal**: A Python script that streams synthetic motor cortex spike data over a TCP socket in a format the Swift app can consume.

#### 1.1 Build Neuron Population Model
- File: `simulator/neural_population.py`
- Class `MotorCortexSimulator` with:
  - Number of neurons (N=100)
  - Each neuron has a preferred direction (random unit vector in 2D)
  - Baseline firing rate (5 Hz) and modulation gain (20 Hz)
  - Method `generate_spikes(vx, vy, dt=0.001)` that returns a list of neuron IDs that fired in that time step (Poisson process).
- Use numpy for fast random generation.

#### 1.2 Define Movement Trajectory
- Add a simple path generator: a circle or figure-8 that yields (vx, vy) over time.
- Allow manual keyboard override (arrow keys) later.

#### 1.3 Implement TCP Server
- File: `simulator/tcp_server.py` (or direct in `main.py`)
- Use `asyncio` to start a TCP server on `localhost:9000`.
- On client connect, continuously stream JSON packets:
  ```json
  {"timestamp": 123456789, "spikes": [0, 4, 12, 34, ...]}
  ```
- Packet rate: 100 Hz (every 10 ms), but each packet encodes spikes that occurred within the last 1 ms bin (for simplicity, aggregate at 10 Hz but note that actual temporal resolution is 1 ms; can be improved later).
- Allow graceful disconnect.
- Add a command-line flag to set duration or infinite loop.

#### 1.4 Test Simulator Independently
- Run `python main.py`
- Use `netcat` or a small test script to verify JSON stream.
- Commit.

---

### Phase 2: Native Mac App Skeleton + TCP Client

**Goal**: The Swift app connects to the simulator, receives spikes, and displays a live raster plot (proof of data flow).

#### 2.1 Implement TCP Client (Swift)
- File: `SpikeReceiver.swift`
- Use `NWConnection` from Network framework (lightweight, async).
- Connect to `localhost:9000` when app launches.
- Continuously read data, parse JSON into a `SpikePacket` struct.
- Publish packets via a Combine `PassthroughSubject<SpikePacket, Never>` for the UI.

#### 2.2 Build Data Model
- Define `SpikePacket` struct (timestamp: TimeInterval, spikes: [Int]).
- Define `NeuronConfig` (id, preferredDirX, preferredDirY) – later loaded from simulator or hardcoded for now.

#### 2.3 Create Raster View
- Use SwiftUI `TimelineView(.periodic(from: .now, by: 0.05))` to redraw at ~20 Hz.
- Draw a canvas where each row is a neuron, and a dot is plotted when a spike occurs.
- Use `Path` + `Canvas` for performance.
- Show a simple raster of 100 neurons, updating in real time.

#### 2.4 Test End-to-End
- Start simulator, then run the app.
- Verify raster updates in sync with simulated spikes.
- Add a text counter for packets received to confirm connectivity.

#### 2.5 Basic UI Layout
- `ContentView.swift`: 
  - Left pane: Raster view
  - Right pane: Placeholder for future cursor canvas
  - Bottom: Status bar (connection state, packet rate)
