#pragma once

// =============================================================================
// AI CONTEXT & DOCUMENTATION
// Phase: 3 (NeuroPilot Core - Task 3.1)
// Purpose: High-performance 2D velocity prediction Kalman Filter in native C++.
// Algorithm: Linear Dynamical System (LDS) state estimator for neural decoding:
//              x_t = A * x_{t-1} + w_t,   w_t ~ N(0, W)
//              z_t = H * x_t + q_t,       q_t ~ N(0, Q)
// Fast Path: Dual / Woodbury matrix inversion (inverts d x d instead of N x N)
//            plus steady-state gain compilation for sub-microsecond online inference.
// Downstream: Bridged to Python via pybind11 (3.2) and Swift via Obj-C++ (3.3).
// =============================================================================

#include "neuropilot/matrix.hpp"
#include <vector>
#include <utility>
#include <string>

namespace neuropilot {

struct KalmanConfig {
    size_t state_dim = 2;       // 2 for [vx, vy], or 3 for [vx, vy, 1] (affine bias)
    size_t obs_dim = 100;       // 100 neural channels / microelectrode array recording
    double dt = 0.01;           // 10ms bin width (100 Hz)
    bool use_affine_bias = false; // If true, state_dim expands to include constant 1.0
    bool integrate_position = true; // Automatically tracks 2D cursor position (px, py)
};

class KalmanFilter2D {
public:
    explicit KalmanFilter2D(const KalmanConfig& config = KalmanConfig());
    KalmanFilter2D(size_t state_dim, size_t obs_dim, double dt = 0.01);

    // Set model parameters
    void set_transition_matrix(const Matrix& A);
    void set_process_noise(const Matrix& W);
    void set_observation_matrix(const Matrix& H);
    void set_measurement_noise(const Matrix& Q);
    void set_initial_covariance(const Matrix& P0);

    // Access model parameters
    const Matrix& transition_matrix() const { return A_; }
    const Matrix& process_noise() const { return W_; }
    const Matrix& observation_matrix() const { return H_; }
    const Matrix& measurement_noise() const { return Q_; }
    const Matrix& covariance() const { return P_; }

    // State management
    void reset(const Vector& initial_state = Vector());
    const Vector& state() const { return x_; }
    std::pair<double, double> velocity() const;
    std::pair<double, double> position() const;
    void set_position(double px, double py);

    // Online Decoding Steps
    // 1. Time Update (Predict)
    Vector predict();

    // 2. Measurement Update from dense neural firing rate / spike count vector (N x 1)
    Vector update(const Vector& z);

    // One-shot: Predict + Update from dense firing rate / spike counts
    Vector step(const Vector& z);

    // Ingests raw flat array of spike neuron IDs (matching simulator / BLE packet format)
    // Converts sparse IDs to dense bin counts and decodes velocity
    Vector step_spikes(const std::vector<int>& spike_ids);

    // Offline Calibration / Fitting
    // Fits A, W, H, Q from paired kinematic trajectory & neural firing rate time-series
    void fit(const std::vector<Vector>& kinematics,
             const std::vector<Vector>& neural_observations,
             double ridge_lambda = 1e-5);

    // Steady-State Compilation
    // Iterates Riccati equation to convergence and compiles steady-state matrices:
    // x_t = M1 * x_{t-1} + M2 * z_t
    void compute_steady_state(size_t max_iterations = 500, double tolerance = 1e-7);
    bool is_steady_state_ready() const { return steady_state_ready_; }
    Vector step_steady_state(const Vector& z);

private:
    KalmanConfig config_;
    size_t d_; // Effective state dimension
    size_t n_; // Observation dimension (channels)

    // System Matrices
    Matrix A_; // State transition (d x d)
    Matrix W_; // Process noise covariance (d x d)
    Matrix H_; // Observation matrix (n x d)
    Matrix Q_; // Measurement noise covariance (n x n)
    Matrix P_; // State covariance (d x d)
    Vector x_; // Current state estimate (d)

    // Integrated Position
    double px_ = 0.0;
    double py_ = 0.0;

    // Steady-state cached matrices
    bool steady_state_ready_ = false;
    Matrix K_steady_;  // Steady-state Kalman Gain (d x n)
    Matrix M1_steady_; // (I - K_steady * H) * A (d x d)
    Matrix M2_steady_; // K_steady (d x n)

    void initialize_default_matrices();
};

} // namespace neuropilot
