# BCI Datasets

This directory is dedicated to storing rich, high-quality prerecorded neuro-datasets (such as `.mat`, `.nwb`, or `.h5` files) used for offline analysis and for driving our real-time simulator with real-world spike data.

## Target Datasets (Phase 2.1)

To ensure the `NeuroPilot Core` decoder is built against real physiological noise and variance, we will be sourcing data from industry-standard benchmarks.

Our primary targets are:
1. **The FALCON Benchmark Datasets**: High-quality, curated implantable BCI (iBCI) data focusing on cursor/movement tasks in both non-human primates and human subjects.
2. **Sabes Lab Motor Cortex Data**: The classic gold standard monkey dataset (often used via the `bci-decoders` repository) for testing continuous 2D movement decoding (Kalman Filters).

*Note: Large dataset files should be added to `.gitignore` to avoid bloating the repository. Only place small samples, scripts, or `.gitignore` entries here.*
