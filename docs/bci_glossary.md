# Brain-Computer Interface (BCI) Glossary & Domain Knowledge

Welcome to the NeuroPilot domain knowledge guide. Brain-Computer Interfaces (BCIs) combine neuroscience, electrical engineering, signal processing, and high-performance software development. 

If you are new to the field, this glossary breaks down the core concepts and explains the specific purpose of each component within the NeuroPilot architecture.

---

## 🧠 Neuroscience Fundamentals

- **Motor Cortex**: The region of the cerebral cortex involved in the planning, control, and execution of voluntary movements. In motor BCI applications (like helping paralyzed individuals use computers), implants are placed here to decode a user's intent to move.
- **Spike (Action Potential)**: The rapid electrical discharge of a neuron. When a neuron "fires," it emits a spike. In our software, we treat these as discrete digital events.
- **Firing Rate**: The number of spikes a neuron emits over a specific period of time (e.g., spikes per second, or Hz). The brain encodes information in firing rates—for example, a higher firing rate might indicate a stronger desire to move a mouse cursor.
- **Preferred Direction**: In the motor cortex, individual neurons often exhibit "directional tuning." A specific neuron will fire at its absolute maximum rate when the user intends to move in its "preferred direction," and at its lowest baseline rate when moving in the opposite direction.

---

## ⚡ Hardware & Data Acquisition

- **Microelectrode Array (MEA)**: A physical grid of tiny microscopic electrodes implanted directly into brain tissue to record the electrical activity of nearby neurons. 
- **Threshold Crossing**: The physical array records continuous analog voltage. A "threshold crossing" occurs when that voltage sharply spikes above a predefined limit, signifying that a neuron has fired. Our `N1Fusion Link` simulator skips the analog voltage processing step and directly outputs these threshold crossings as discrete spike IDs.
- **Telemetry**: The process of wirelessly transmitting the recorded neural data from the implant to an external receiver (like a phone or computer). Our simulated telemetry stream mimics this real-time, low-latency data transmission.

---

## 🧮 Algorithms & Decoding

- **Cosine Tuning**: A mathematical model used to simulate a neuron's firing rate based on movement direction. It calculates the dot product between the intended movement vector and the neuron's preferred direction. Our simulator uses this model to realistically generate synthetic spikes.
- **Decoder**: The core C++ engine (`NeuroPilot Core`) responsible for translating raw incoming neural spikes back into a predicted movement intent (e.g., moving a cursor).
- **Population Vector**: A fundamental decoding algorithm. It takes the preferred direction of every neuron, scales each by how many times that neuron fired in the current time bin, and sums them all together to calculate the user's intended movement.
- **Kalman Filter**: An advanced, statistically optimal decoding algorithm. It uses both the current neural spikes and the *previous* state of the cursor (velocity/position) to smoothly and accurately predict the next movement. It handles neurological noise much better than a Population Vector.

---

## 📊 System Metrics & Visualization

- **Kinematics**: The physical properties of movement (position, velocity, acceleration). In our simulator, the "simulated movement kinematics" represent the *Ground Truth*—what the user is actually trying to do.
- **Raster Plot**: A standard neuroscience visualization tool. It plots time on the X-axis and neuron IDs on the Y-axis. Every time a neuron fires, a dot is placed on its row. This provides a fast, visual way to see population-level firing patterns.
- **Decoding Error**: The mathematical difference between the user's true intended movement (Ground Truth Kinematics) and the movement calculated by our software Decoder. Minimizing this error is the primary goal of BCI software engineering.
