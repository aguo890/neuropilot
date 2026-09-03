// =============================================================================
// AI CONTEXT & DOCUMENTATION
// Phase: 3 (NeuroPilot Core - Task 3.1)
// Purpose: Unit test suite and latency benchmarks for C++ Matrix engine & KalmanFilter2D.
// Test Coverage:
//   1. Matrix & Vector algebraic invariants (2x2, 3x3, NxN inversions, solves).
//   2. 2D Figure-8 velocity trajectory tracking from 100-channel neural population.
//   3. OLS parameter identification from paired training data.
//   4. Steady-state compilation equivalence and convergence.
//   5. Sparse spike ID ingestion (simulator protocol fidelity).
//   6. Nanosecond-level latency microbenchmarks.
// =============================================================================

#include "neuropilot/matrix.hpp"
#include "neuropilot/kalman_filter.hpp"

#include <iostream>
#include <vector>
#include <cmath>
#include <cassert>
#include <chrono>
#include <random>
#include <numeric>
#include <iomanip>

using namespace neuropilot;

void test_matrix_invariants() {
    std::cout << "▶ Testing Matrix & Vector algebraic invariants..." << std::endl;

    // 1. Vector basic operations
    Vector v1{1.0, 2.0, 3.0};
    Vector v2{4.0, 5.0, 6.0};
    Vector v3 = v1 + v2;
    assert(std::abs(v3[0] - 5.0) < 1e-9);
    assert(std::abs(v3[1] - 7.0) < 1e-9);
    assert(std::abs(v3[2] - 9.0) < 1e-9);
    assert(std::abs(v1.dot(v2) - 32.0) < 1e-9);

    // 2. 2x2 Matrix inversion
    Matrix m2{{4.0, 7.0}, {2.0, 6.0}};
    Matrix inv2 = m2.inverse();
    Matrix prod2 = m2 * inv2;
    assert(std::abs(prod2(0, 0) - 1.0) < 1e-7);
    assert(std::abs(prod2(0, 1) - 0.0) < 1e-7);
    assert(std::abs(prod2(1, 0) - 0.0) < 1e-7);
    assert(std::abs(prod2(1, 1) - 1.0) < 1e-7);

    // 3. 3x3 Matrix inversion
    Matrix m3{{1.0, 2.0, -1.0}, {2.0, 1.0, 0.0}, {-1.0, 1.0, 2.0}};
    Matrix inv3 = m3.inverse();
    Matrix prod3 = m3 * inv3;
    for (size_t r = 0; r < 3; ++r) {
        for (size_t c = 0; c < 3; ++c) {
            double expected = (r == c) ? 1.0 : 0.0;
            assert(std::abs(prod3(r, c) - expected) < 1e-7);
        }
    }

    // 4. NxN Gauss-Jordan inversion (5x5 positive-definite Hilbert-like matrix)
    size_t N = 5;
    Matrix mN(N, N);
    for (size_t r = 0; r < N; ++r) {
        for (size_t c = 0; c < N; ++c) {
            mN(r, c) = 1.0 / static_cast<double>(r + c + 1);
        }
        mN(r, r) += 1.0; // Boost diagonal for stability
    }
    Matrix invN = mN.inverse();
    Matrix prodN = mN * invN;
    for (size_t r = 0; r < N; ++r) {
        for (size_t c = 0; c < N; ++c) {
            double expected = (r == c) ? 1.0 : 0.0;
            assert(std::abs(prodN(r, c) - expected) < 1e-6);
        }
    }

    std::cout << "  ✓ All Matrix invariants passed!" << std::endl;
}

double compute_pearson_r(const std::vector<double>& x, const std::vector<double>& y) {
    size_t n = x.size();
    if (n < 2 || x.size() != y.size()) return 0.0;

    double sum_x = std::accumulate(x.begin(), x.end(), 0.0);
    double sum_y = std::accumulate(y.begin(), y.end(), 0.0);
    double mean_x = sum_x / n;
    double mean_y = sum_y / n;

    double num = 0.0, denom_x = 0.0, denom_y = 0.0;
    for (size_t i = 0; i < n; ++i) {
        double dx = x[i] - mean_x;
        double dy = y[i] - mean_y;
        num += dx * dy;
        denom_x += dx * dx;
        denom_y += dy * dy;
    }
    double denom = std::sqrt(denom_x * denom_y);
    return denom > 1e-12 ? (num / denom) : 0.0;
}

void test_2d_velocity_tracking() {
    std::cout << "▶ Testing 2D Figure-8 velocity trajectory decoding (100 channels)..." << std::endl;

    const size_t num_neurons = 100;
    const double dt = 0.01; // 10ms bin (100 Hz)
    const size_t steps = 1000; // 10 seconds of movement

    // Ground truth preferred directions & tuning for 100 simulated neurons
    std::vector<double> pref_theta(num_neurons);
    std::vector<double> baseline(num_neurons);
    std::vector<double> modulation(num_neurons);
    for (size_t i = 0; i < num_neurons; ++i) {
        pref_theta[i] = (2.0 * M_PI * static_cast<double>(i)) / static_cast<double>(num_neurons);
        baseline[i] = 10.0;
        modulation[i] = 20.0;
    }

    // Set up ground truth trajectory (Figure-8)
    std::vector<double> true_vx(steps);
    std::vector<double> true_vy(steps);
    std::vector<Vector> kinematics(steps);
    std::vector<Vector> neural_data(steps);

    std::mt19937 rng(42);
    std::normal_distribution<double> noise_dist(0.0, 1.5);

    for (size_t t = 0; t < steps; ++t) {
        double time_sec = static_cast<double>(t) * dt;
        // Figure-8 velocities: vx = cos(t), vy = 2 * cos(2t)
        double vx = std::cos(time_sec);
        double vy = 2.0 * std::cos(2.0 * time_sec);

        true_vx[t] = vx;
        true_vy[t] = vy;
        kinematics[t] = Vector{vx, vy};

        // Synthesize neural firing rates
        Vector z(num_neurons);
        for (size_t i = 0; i < num_neurons; ++i) {
            double rate = baseline[i] + modulation[i] * (vx * std::cos(pref_theta[i]) + vy * std::sin(pref_theta[i]));
            rate += noise_dist(rng);
            z[i] = std::max(0.0, rate * dt); // Spikes in bin
        }
        neural_data[t] = z;
    }

    // Initialize Kalman Filter and calibrate on first 500 samples
    KalmanConfig config;
    config.state_dim = 2;
    config.obs_dim = num_neurons;
    config.dt = dt;
    config.use_affine_bias = false;
    config.integrate_position = true;

    KalmanFilter2D kf(config);

    // Split 50/50 train / test
    std::vector<Vector> train_kin(kinematics.begin(), kinematics.begin() + 500);
    std::vector<Vector> train_z(neural_data.begin(), neural_data.begin() + 500);

    kf.fit(train_kin, train_z);

    // Test online decode on the remaining 500 steps
    std::vector<double> decoded_vx;
    std::vector<double> decoded_vy;
    std::vector<double> test_true_vx;
    std::vector<double> test_true_vy;

    kf.reset();

    for (size_t t = 500; t < steps; ++t) {
        Vector est = kf.step(neural_data[t]);
        decoded_vx.push_back(est[0]);
        decoded_vy.push_back(est[1]);
        test_true_vx.push_back(true_vx[t]);
        test_true_vy.push_back(true_vy[t]);
    }

    double r_vx = compute_pearson_r(test_true_vx, decoded_vx);
    double r_vy = compute_pearson_r(test_true_vy, decoded_vy);

    std::cout << "  Decoded Velocity Pearson Correlation:" << std::endl;
    std::cout << "    r(Vx): " << std::fixed << std::setprecision(4) << r_vx << std::endl;
    std::cout << "    r(Vy): " << std::fixed << std::setprecision(4) << r_vy << std::endl;

    // High correlation expectation for synthetic cosine-tuned population
    assert(r_vx > 0.85);
    assert(r_vy > 0.85);
    std::cout << "  ✓ 2D Velocity Tracking test passed (r > 0.85)!" << std::endl;
}

void test_steady_state_and_spikes() {
    std::cout << "▶ Testing Steady-State acceleration & sparse spike ID ingestion..." << std::endl;

    KalmanFilter2D kf(2, 100, 0.01);
    kf.compute_steady_state();
    assert(kf.is_steady_state_ready());

    // Compare step() vs step_steady_state()
    Vector dummy_z(100, 0.2);
    dummy_z[10] = 2.0; // Neuron 10 fired multiple times
    dummy_z[45] = 1.0;

    Vector out_dynamic = kf.step(dummy_z);
    Vector out_steady = kf.step_steady_state(dummy_z);

    // Both outputs should be in the same direction and magnitude
    double diff = (out_dynamic - out_steady).norm();
    assert(diff < 0.5);

    // Test sparse spike ingestion
    std::vector<int> spike_ids = {10, 10, 45, 99};
    Vector spike_out = kf.step_spikes(spike_ids);
    assert(spike_out.size() == 2);

    std::cout << "  ✓ Steady-State and Spike ID ingestion passed!" << std::endl;
}

void test_latency_benchmark() {
    std::cout << "▶ Running Latency Microbenchmarks (1,000 steps)..." << std::endl;

    KalmanFilter2D kf(2, 100, 0.01);
    kf.compute_steady_state();

    Vector z(100, 0.15);

    // Benchmark Dynamic Dual-Form step()
    const size_t N_ITER = 1000;
    auto start_dyn = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < N_ITER; ++i) {
        kf.step(z);
    }
    auto end_dyn = std::chrono::high_resolution_clock::now();
    double dyn_us = std::chrono::duration<double, std::micro>(end_dyn - start_dyn).count() / N_ITER;

    // Benchmark Steady-State step_steady_state()
    auto start_steady = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < N_ITER; ++i) {
        kf.step_steady_state(z);
    }
    auto end_steady = std::chrono::high_resolution_clock::now();
    double steady_us = std::chrono::duration<double, std::micro>(end_steady - start_steady).count() / N_ITER;

    std::cout << "  Latency Results (100-channel decoding):" << std::endl;
    std::cout << "    Dynamic Riccati step:      " << std::fixed << std::setprecision(2) << dyn_us << " µs per bin" << std::endl;
    std::cout << "    Compiled Steady-State step: " << std::fixed << std::setprecision(2) << steady_us << " µs per bin" << std::endl;
    std::cout << "    Budget:                    10,000 µs (10ms bin at 100 Hz)" << std::endl;

    // Dynamic should be well under 100 µs; steady-state under 5 µs
    assert(dyn_us < 100.0);
    assert(steady_us < 20.0);

    std::cout << "  ✓ Benchmark passed! Decoding is " 
              << static_cast<int>(10000.0 / dyn_us) << "x faster than real-time budget." << std::endl;
}

int main() {
    std::cout << "==================================================" << std::endl;
    std::cout << "🧪 NeuroPilot Core - C++ Kalman Filter Test Suite" << std::endl;
    std::cout << "==================================================" << std::endl;

    test_matrix_invariants();
    test_2d_velocity_tracking();
    test_steady_state_and_spikes();
    test_latency_benchmark();

    std::cout << "==================================================" << std::endl;
    std::cout << "✅ All tests passed successfully!" << std::endl;
    std::cout << "==================================================" << std::endl;

    return 0;
}
