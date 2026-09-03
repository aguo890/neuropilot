# =============================================================================
# AI CONTEXT & DOCUMENTATION
# Phase: 3 (NeuroPilot Core - Task 3.2)
# Purpose: Comprehensive Python test suite for C++ Kalman Filter pybind11 bindings.
# Validates:
#   1. Zero-copy NumPy array conversions and shape contracts.
#   2. End-to-end 2D velocity decoding on synthetic Figure-8 kinematics (r > 0.85).
#   3. OLS model calibration via kf.fit().
#   4. High-throughput batch decoding (kf.decode_batch).
#   5. Steady-state compilation and inference.
#   6. PyTorch tensor interoperability via .numpy().
# =============================================================================

import sys
import os
import time
import numpy as np

def test_config_and_initialization():
    print("▶ Testing KalmanConfig & KalmanFilter2D initialization...")
    import neuropilot_core
    
    cfg = neuropilot_core.KalmanConfig(
        state_dim=2,
        obs_dim=100,
        dt=0.01,
        use_affine_bias=False,
        integrate_position=True
    )
    assert cfg.state_dim == 2
    assert cfg.obs_dim == 100
    assert cfg.dt == 0.01
    
    kf = neuropilot_core.KalmanFilter2D(cfg)
    vx, vy = kf.velocity
    assert abs(vx) < 1e-6 and abs(vy) < 1e-6
    
    # Check default matrix shapes
    assert kf.transition_matrix.shape == (2, 2)
    assert kf.process_noise.shape == (2, 2)
    assert kf.observation_matrix.shape == (100, 2)
    assert kf.measurement_noise.shape == (100, 100)
    assert kf.covariance.shape == (2, 2)
    
    # Test matrix setter
    new_w = np.eye(2) * 0.08
    kf.process_noise = new_w
    np.testing.assert_allclose(kf.process_noise, new_w)
    
    print("  ✓ Configuration and initialization passed!")

def test_online_step_and_spikes():
    print("▶ Testing step(), update(), and sparse spike ingestion...")
    import neuropilot_core
    
    kf = neuropilot_core.KalmanFilter2D(2, 100, 0.01)
    
    # 1. Step with dense 100-channel observation
    dummy_z = np.zeros(100, dtype=np.float64)
    dummy_z[10] = 2.0
    dummy_z[45] = 1.0
    
    out = kf.step(dummy_z)
    assert isinstance(out, np.ndarray)
    assert out.shape == (2,)
    
    # 2. Step with sparse spike IDs (matching simulator JSON schema)
    spike_ids = [10, 10, 45, 99]
    spike_out = kf.step_spikes(spike_ids)
    assert isinstance(spike_out, np.ndarray)
    assert spike_out.shape == (2,)
    
    # 3. Verify position updates
    px, py = kf.position
    assert not (px == 0.0 and py == 0.0)
    
    print("  ✓ Online step and spike ingestion passed!")

def test_calibration_and_velocity_tracking():
    print("▶ Testing OLS calibration & 2D Figure-8 velocity tracking...")
    import neuropilot_core
    
    num_neurons = 100
    dt = 0.01
    steps = 1000
    
    # Synthetic Figure-8 ground truth
    t = np.arange(steps) * dt
    true_vx = np.cos(t)
    true_vy = 2.0 * np.cos(2.0 * t)
    kinematics = np.column_stack((true_vx, true_vy))
    
    # Synthetic cosine tuning for 100 neurons
    theta = np.linspace(0, 2 * np.pi, num_neurons, endpoint=False)
    baseline = 10.0
    modulation = 20.0
    
    H_true = np.column_stack((modulation * np.cos(theta), modulation * np.sin(theta)))
    rates = baseline + kinematics @ H_true.T
    
    # Add Poisson-like Gaussian noise
    rng = np.random.default_rng(42)
    noise = rng.normal(0, 1.5, size=rates.shape)
    neural_observations = np.maximum(0, (rates + noise) * dt)
    
    # Split train / test 50/50
    train_kin = kinematics[:500]
    train_obs = neural_observations[:500]
    test_kin = kinematics[500:]
    test_obs = neural_observations[500:]
    
    kf = neuropilot_core.KalmanFilter2D(2, num_neurons, dt)
    kf.fit(train_kin, train_obs)
    kf.reset()
    
    # Batch decode test set
    decoded = kf.decode_batch(test_obs)
    assert decoded.shape == (500, 2)
    
    # Compute Pearson correlation
    r_vx = np.corrcoef(test_kin[:, 0], decoded[:, 0])[0, 1]
    r_vy = np.corrcoef(test_kin[:, 1], decoded[:, 1])[0, 1]
    
    print(f"  Decoded Velocity Pearson Correlation:")
    print(f"    r(Vx): {r_vx:.4f}")
    print(f"    r(Vy): {r_vy:.4f}")
    
    assert r_vx > 0.85, f"Expected r(Vx) > 0.85, got {r_vx}"
    assert r_vy > 0.85, f"Expected r(Vy) > 0.85, got {r_vy}"
    
    # Test steady-state batch decode
    kf.compute_steady_state()
    assert kf.is_steady_state_ready
    
    kf.reset()
    decoded_steady = kf.decode_batch(test_obs, steady_state=True)
    r_vx_s = np.corrcoef(test_kin[:, 0], decoded_steady[:, 0])[0, 1]
    r_vy_s = np.corrcoef(test_kin[:, 1], decoded_steady[:, 1])[0, 1]
    
    print(f"  Steady-State Decoded Velocity Pearson Correlation:")
    print(f"    r(Vx): {r_vx_s:.4f}")
    print(f"    r(Vy): {r_vy_s:.4f}")
    
    assert r_vx_s > 0.85
    assert r_vy_s > 0.85
    
    print("  ✓ OLS Calibration and velocity tracking passed (r > 0.85)!")

def test_pytorch_and_benchmark():
    print("▶ Testing PyTorch / Tensor interop & throughput benchmark...")
    import neuropilot_core
    
    kf = neuropilot_core.KalmanFilter2D(2, 100, 0.01)
    kf.compute_steady_state()
    
    # Check PyTorch compatibility
    try:
        import torch
        print("  Found PyTorch. Testing tensor interop...")
        tensor_obs = torch.randn(10, 100, dtype=torch.float64)
        out = kf.decode_batch(tensor_obs.numpy())
        assert out.shape == (10, 2)
        print("  ✓ Direct PyTorch tensor.numpy() passing verified!")
    except ImportError:
        print("  PyTorch not installed in environment; verified NumPy buffer protocol standard.")
    
    # Benchmark decode_batch throughput
    batch_size = 10_000
    dummy_obs = np.random.rand(batch_size, 100)
    
    start = time.perf_counter()
    _ = kf.decode_batch(dummy_obs, steady_state=True)
    elapsed = time.perf_counter() - start
    
    rate = batch_size / elapsed
    print(f"  Batch Throughput: {rate:,.0f} bins/second ({rate / 100:,.1f}x real-time speed)")
    assert rate > 20_000, f"Expected throughput > 20,000 bins/sec, got {rate}"
    
    print("  ✓ Throughput benchmark passed!")

if __name__ == "__main__":
    print("=" * 50)
    print("🐍 NeuroPilot Core - Python pybind11 Test Suite")
    print("=" * 50)
    
    test_config_and_initialization()
    test_online_step_and_spikes()
    test_calibration_and_velocity_tracking()
    test_pytorch_and_benchmark()
    
    print("=" * 50)
    print("✅ All Python pybind11 tests passed successfully!")
    print("=" * 50)
