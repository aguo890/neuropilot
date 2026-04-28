# BCI Open-Source References & Prior Art

Below is a complete directory of GitHub repositories and research papers representing the state-of-the-art in open-source Brain-Computer Interface (BCI) development. This provides context on what exists, what can be learned from, and precisely where NeuroPilot fits into the ecosystem.

---

### 1. General-Purpose BCI Research Frameworks

These are the foundational, do-everything platforms built for academic EEG research.

*   **BCI2000** — the most widely used general-purpose BCI platform, written primarily in C++ with a real-time processing pipeline.
    *   **Main source code mirror:** [https://github.com/neurotechcenter/BCI2000](https://github.com/neurotechcenter/BCI2000) 
    *   **Official website (source downloads, binaries, docs):** [https://www.bci2000.org](https://www.bci2000.org) 
    *   **Python-based extension (BCPy2000):** [https://github.com/neurotechcenter/BCpy2000](https://github.com/neurotechcenter/BCpy2000) 
    *   **Unity integration (UnityBCI2000):** [https://github.com/neurotechcenter/UnityBCI2000](https://github.com/neurotechcenter/UnityBCI2000) 

*   **MetaBCI** — China's first open-source platform for non-invasive BCI, led by Tianjin University, with three components: `brainda` (data/datasets), `brainflow` (online processing), and `brainstim` (experiment design).
    *   **Primary repo:** [https://github.com/TBC-TJU/MetaBCI](https://github.com/TBC-TJU/MetaBCI) 
    *   **Forked mirror (UESTC-BAC):** [https://github.com/UESTC-BAC/MetaBCI-UESTC](https://github.com/UESTC-BAC/MetaBCI-UESTC) 
    *   **PyPI package:** [https://pypi.org/project/metabci](https://pypi.org/project/metabci) 

---

### 2. Hardware Interface & Biosignal Libraries

These focus on the critical job of talking to hardware and acquiring clean signals.

*   **OpenBCI** — the gold standard for open-source BCI hardware and its accompanying software ecosystem.
    *   **Organization home:** [https://github.com/OpenBCI](https://github.com/OpenBCI) 
    *   **GUI application (cross-platform):** [https://github.com/OpenBCI/OpenBCI_GUI](https://github.com/OpenBCI/OpenBCI_GUI) 
    *   **Ganglion board firmware library:** [https://github.com/OpenBCI/OpenBCI_Ganglion_Library](https://github.com/OpenBCI/OpenBCI_Ganglion_Library) 
    *   **Cyton board Arduino library:** [https://github.com/OpenBCI/OpenBCI_Cyton_Library](https://github.com/OpenBCI/OpenBCI_Cyton_Library) 
    *   **Radio modules firmware:** [https://github.com/OpenBCI/OpenBCI_Radios](https://github.com/OpenBCI/OpenBCI_Radios) 
    *   **Tutorials:** [https://github.com/OpenBCI/OpenBCI_Tutorials](https://github.com/OpenBCI/OpenBCI_Tutorials) 

*   **BrainFlow** — a library providing a uniform SDK to obtain, parse, and analyze EEG, EMG, ECG, and other biosensor data, with bindings for Python, Java, C++, C#, R, MATLAB, and Julia.
    *   **Primary repo:** [https://github.com/brainflow-dev/brainflow](https://github.com/brainflow-dev/brainflow) 
    *   **Website:** [https://brainflow.org](https://brainflow.org) 
    *   **Documentation:** [https://brainflow.readthedocs.io](https://brainflow.readthedocs.io) 

---

### 3. Modular Experiment Platforms

These are modern, Python-based frameworks designed for rapid, flexible experiment design and deployment.

*   **PyNoetic** — an end-to-end Python framework for no-code development of EEG brain-computer interfaces, featuring a full GUI for stimulus presentation, data acquisition, filtering, feature extraction, ML classification, and simulation.
    *   **Primary repo:** [https://github.com/NeuroDiag/PyNoetic-official](https://github.com/NeuroDiag/PyNoetic-official) 
    *   **Paper (PLOS ONE, 2025):** [https://arxiv.org/abs/2508.10367](https://arxiv.org/abs/2508.10367) 

*   **MEDUSA©** — a Python-based software ecosystem with two components: MEDUSA© Kernel (signal processing, ML, deep learning) and MEDUSA© Platform (desktop GUI for BCI and cognitive neuroscience experiments with an app marketplace).
    *   **Platform repo:** [https://github.com/medusabci/medusa-platform](https://github.com/medusabci/medusa-platform) 
    *   **Kernel repo:** [https://github.com/medusabci/medusa-kernel](https://github.com/medusabci/medusa-kernel) 
    *   **c-VEP Speller app:** [https://github.com/medusabci/app-cvep-speller](https://github.com/medusabci/app-cvep-speller) 
    *   **Website:** [https://www.medusabci.com](https://www.medusabci.com) 
    *   **Documentation:** [https://docs.medusabci.com](https://docs.medusabci.com) 
    *   **PyPI (kernel):** [https://pypi.org/project/medusa-kernel](https://pypi.org/project/medusa-kernel) 

*   **Dareplane** — a modular, technology-agnostic open-source platform for BCI research with a primary application focus on adaptive deep brain stimulation (aDBS). Uses LSL for data and TCP sockets for module communication.
    *   **Primary repo (overview + individual modules):** [https://github.com/bsdlab/Dareplane](https://github.com/bsdlab/Dareplane) 
    *   **Strawman module template:** [https://github.com/bsdlab/dp-strawman-module](https://github.com/bsdlab/dp-strawman-module) 
    *   **Control room (central orchestrator):** [https://github.com/bsdlab/dp-control-room](https://github.com/bsdlab/dp-control-room) 
    *   **Documentation:** [https://bsdlab.github.io/Dareplane](https://bsdlab.github.io/Dareplane) 
    *   **Paper (J. Neural Eng., 2025):** [https://iopscience.iop.org/article/10.1088/1741-2552/adbb20](https://iopscience.iop.org/article/10.1088/1741-2552/adbb20) 

---

### 4. Decoding Algorithms & Benchmarks

These are specialized repositories focused specifically on the mathematical core of BCI: neural decoding algorithms and standardized performance evaluation.

*   **BCI Decoders Benchmark (seanmperkins)** — benchmarks four common neural decode algorithms (Kalman Filter, Wiener Filter, Feedforward Neural Network, and GRU) for offline decoding on three monkey motor/somatosensory cortex datasets.
    *   **Primary repo:** [https://github.com/seanmperkins/bci-decoders](https://github.com/seanmperkins/bci-decoders) 

*   **MOABB (Mother of All BCI Benchmarks)** — a comprehensive framework for trustworthy benchmarking of BCI decoding algorithms across 12+ open-access datasets and 250+ subjects.
    *   **Primary repo:** [https://github.com/NeuroTechX/moabb](https://github.com/NeuroTechX/moabb) 
    *   **Paper (J. Neural Eng., 2018):** [https://iopscience.iop.org/article/10.1088/1741-2552/aade5d](https://iopscience.iop.org/article/10.1088/1741-2552/aade5d) 

*   **FALCON (Few-shot Algorithms for COnsistent Neural decoding)** — a newer benchmark suite specifically designed to standardize evaluation of iBCI robustness across movement and communication tasks.
    *   **Website & repo:** [https://snel-repo.github.io/falcon](https://snel-repo.github.io/falcon) 
    *   **Paper (bioRxiv, 2024):** [https://www.biorxiv.org/content/10.1101/2024.09.16.613324](https://www.biorxiv.org/content/10.1101/2024.09.16.613324) 

---

### NeuroPilot's Place in the Ecosystem

These repositories collectively form the library of prior art for the BCI engineering community. Most existing open-source solutions focus on general-purpose EEG academic research (like BCI2000 or MetaBCI) or offline algorithm benchmarking (like MOABB).

None of them target the specific low-latency, modular pipeline required for high-bandwidth, implantable cortical arrays (iBCIs) in a modern native environment. This vacuum is precisely where **NeuroPilot** makes its contribution—serving as the foundational bridge between these academic mathematical models and robust, real-time consumer software.
