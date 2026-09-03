// =============================================================================
// AI CONTEXT & DOCUMENTATION
// Phase: 3 (NeuroPilot Core - Task 3.2)
// Purpose: Pybind11 Python bindings exposing the C++ KalmanFilter2D and Matrix engine.
// Interoperability: Native buffer protocol for zero-overhead NumPy array passing.
// Downstream: Enables PyTorch / NumPy algorithm training and batch offline validation.
// =============================================================================

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>

#include "neuropilot/matrix.hpp"
#include "neuropilot/kalman_filter.hpp"

#include <vector>
#include <sstream>
#include <stdexcept>

namespace py = pybind11;
using namespace neuropilot;

// =============================================================================
// NumPy <-> Native Conversions
// =============================================================================

py::array_t<double> matrix_to_numpy(const Matrix& mat) {
    py::array_t<double> arr({static_cast<py::ssize_t>(mat.rows()), static_cast<py::ssize_t>(mat.cols())});
    py::buffer_info buf = arr.request();
    double* ptr = static_cast<double*>(buf.ptr);
    const double* src = mat.data();
    std::copy(src, src + (mat.rows() * mat.cols()), ptr);
    return arr;
}

Matrix numpy_to_matrix(py::array_t<double, py::array::c_style | py::array::forcecast> arr) {
    py::buffer_info buf = arr.request();
    if (buf.ndim != 2) {
        throw std::invalid_argument("Expected 2D NumPy array for Matrix conversion");
    }
    size_t rows = buf.shape[0];
    size_t cols = buf.shape[1];
    const double* ptr = static_cast<const double*>(buf.ptr);
    std::vector<double> data(ptr, ptr + (rows * cols));
    return Matrix(rows, cols, data);
}

py::array_t<double> vector_to_numpy(const Vector& vec) {
    py::array_t<double> arr(static_cast<py::ssize_t>(vec.size()));
    py::buffer_info buf = arr.request();
    double* ptr = static_cast<double*>(buf.ptr);
    const double* src = vec.data();
    std::copy(src, src + vec.size(), ptr);
    return arr;
}

Vector numpy_to_vector(py::array_t<double, py::array::c_style | py::array::forcecast> arr) {
    py::buffer_info buf = arr.request();
    if (buf.ndim != 1) {
        throw std::invalid_argument("Expected 1D NumPy array for Vector conversion");
    }
    size_t size = buf.shape[0];
    const double* ptr = static_cast<const double*>(buf.ptr);
    std::vector<double> data(ptr, ptr + size);
    return Vector(data);
}

// =============================================================================
// Pybind11 Module Definition
// =============================================================================

PYBIND11_MODULE(neuropilot_core, m) {
    m.doc() = "NeuroPilot Core: C++ Kalman Filter neural decoder with PyTorch/NumPy interop";

    // 1. KalmanConfig
    py::class_<KalmanConfig>(m, "KalmanConfig")
        .def(py::init<size_t, size_t, double, bool, bool>(),
             py::arg("state_dim") = 2,
             py::arg("obs_dim") = 100,
             py::arg("dt") = 0.01,
             py::arg("use_affine_bias") = false,
             py::arg("integrate_position") = true)
        .def_readwrite("state_dim", &KalmanConfig::state_dim)
        .def_readwrite("obs_dim", &KalmanConfig::obs_dim)
        .def_readwrite("dt", &KalmanConfig::dt)
        .def_readwrite("use_affine_bias", &KalmanConfig::use_affine_bias)
        .def_readwrite("integrate_position", &KalmanConfig::integrate_position)
        .def("__repr__", [](const KalmanConfig& c) {
            std::ostringstream oss;
            oss << "KalmanConfig(state_dim=" << c.state_dim 
                << ", obs_dim=" << c.obs_dim 
                << ", dt=" << c.dt 
                << ", use_affine_bias=" << (c.use_affine_bias ? "True" : "False")
                << ", integrate_position=" << (c.integrate_position ? "True" : "False") << ")";
            return oss.str();
        });

    // 2. KalmanFilter2D
    py::class_<KalmanFilter2D>(m, "KalmanFilter2D")
        .def(py::init<const KalmanConfig&>(), py::arg("config"))
        .def(py::init<size_t, size_t, double>(),
             py::arg("state_dim") = 2,
             py::arg("obs_dim") = 100,
             py::arg("dt") = 0.01)

        // System matrix accessors (using NumPy arrays)
        .def_property("transition_matrix",
            [](const KalmanFilter2D& kf) { return matrix_to_numpy(kf.transition_matrix()); },
            [](KalmanFilter2D& kf, py::array_t<double> arr) { kf.set_transition_matrix(numpy_to_matrix(arr)); },
            "State transition matrix A (d x d)")
        .def_property("process_noise",
            [](const KalmanFilter2D& kf) { return matrix_to_numpy(kf.process_noise()); },
            [](KalmanFilter2D& kf, py::array_t<double> arr) { kf.set_process_noise(numpy_to_matrix(arr)); },
            "Process noise covariance matrix W (d x d)")
        .def_property("observation_matrix",
            [](const KalmanFilter2D& kf) { return matrix_to_numpy(kf.observation_matrix()); },
            [](KalmanFilter2D& kf, py::array_t<double> arr) { kf.set_observation_matrix(numpy_to_matrix(arr)); },
            "Observation tuning matrix H (obs_dim x d)")
        .def_property("measurement_noise",
            [](const KalmanFilter2D& kf) { return matrix_to_numpy(kf.measurement_noise()); },
            [](KalmanFilter2D& kf, py::array_t<double> arr) { kf.set_measurement_noise(numpy_to_matrix(arr)); },
            "Measurement noise covariance matrix Q (obs_dim x obs_dim)")
        .def_property_readonly("covariance",
            [](const KalmanFilter2D& kf) { return matrix_to_numpy(kf.covariance()); },
            "Current state estimation covariance P (d x d)")

        // State accessors
        .def_property_readonly("state",
            [](const KalmanFilter2D& kf) { return vector_to_numpy(kf.state()); },
            "Current state vector (d x 1)")
        .def_property_readonly("velocity",
            [](const KalmanFilter2D& kf) {
                auto v = kf.velocity();
                return py::make_tuple(v.first, v.second);
            },
            "Current decoded 2D velocity as (vx, vy)")
        .def_property_readonly("position",
            [](const KalmanFilter2D& kf) {
                auto p = kf.position();
                return py::make_tuple(p.first, p.second);
            },
            "Integrated 2D position as (px, py)")
        .def("set_position", &KalmanFilter2D::set_position, py::arg("px"), py::arg("py"),
             "Set current cursor position")

        // Reset
        .def("reset", [](KalmanFilter2D& kf, py::object initial_state) {
            if (initial_state.is_none()) {
                kf.reset();
            } else {
                py::array_t<double> arr = initial_state.cast<py::array_t<double>>();
                kf.reset(numpy_to_vector(arr));
            }
        }, py::arg("initial_state") = py::none(), "Reset decoder state and covariance")

        // Online Decode Steps
        .def("predict", [](KalmanFilter2D& kf) {
            Vector v = kf.predict();
            return vector_to_numpy(v);
        }, "Time update (predict step)")

        .def("update", [](KalmanFilter2D& kf, py::array_t<double> z) {
            Vector out = kf.update(numpy_to_vector(z));
            return vector_to_numpy(out);
        }, py::arg("z"), "Measurement update from dense neural observation array")

        .def("step", [](KalmanFilter2D& kf, py::array_t<double> z) {
            Vector out = kf.step(numpy_to_vector(z));
            return vector_to_numpy(out);
        }, py::arg("z"), "Single-call predict + update step from dense observation array")

        .def("step_spikes", [](KalmanFilter2D& kf, const std::vector<int>& spike_ids) {
            Vector out = kf.step_spikes(spike_ids);
            return vector_to_numpy(out);
        }, py::arg("spike_ids"), "Step decoder using sparse neuron spike IDs")

        // Steady-State Acceleration
        .def("compute_steady_state", &KalmanFilter2D::compute_steady_state,
             py::arg("max_iterations") = 500, py::arg("tolerance") = 1e-7,
             "Precompile steady-state Kalman gain and transfer matrices")
        .def_property_readonly("is_steady_state_ready", &KalmanFilter2D::is_steady_state_ready)
        .def("step_steady_state", [](KalmanFilter2D& kf, py::array_t<double> z) {
            Vector out = kf.step_steady_state(numpy_to_vector(z));
            return vector_to_numpy(out);
        }, py::arg("z"), "Sub-microsecond steady-state step")

        // Offline Calibration / Fitting
        .def("fit", [](KalmanFilter2D& kf,
                       py::array_t<double, py::array::c_style | py::array::forcecast> kin,
                       py::array_t<double, py::array::c_style | py::array::forcecast> obs,
                       double ridge_lambda) {
            py::buffer_info k_buf = kin.request();
            py::buffer_info o_buf = obs.request();
            if (k_buf.ndim != 2 || o_buf.ndim != 2) {
                throw std::invalid_argument("Expected 2D arrays for kinematics and neural observations");
            }
            size_t T = static_cast<size_t>(k_buf.shape[0]);
            if (static_cast<size_t>(o_buf.shape[0]) != T) {
                throw std::invalid_argument("Time sample count mismatch between kinematics and neural observations");
            }
            size_t d = k_buf.shape[1];
            size_t n = o_buf.shape[1];

            const double* k_ptr = static_cast<const double*>(k_buf.ptr);
            const double* o_ptr = static_cast<const double*>(o_buf.ptr);

            std::vector<Vector> kin_vecs(T);
            std::vector<Vector> obs_vecs(T);
            for (size_t t = 0; t < T; ++t) {
                kin_vecs[t] = Vector(std::vector<double>(k_ptr + t * d, k_ptr + (t + 1) * d));
                obs_vecs[t] = Vector(std::vector<double>(o_ptr + t * n, o_ptr + (t + 1) * n));
            }
            kf.fit(kin_vecs, obs_vecs, ridge_lambda);
        }, py::arg("kinematics"), py::arg("neural_observations"), py::arg("ridge_lambda") = 1e-5,
           "Fit model parameters A, W, H, Q from paired kinematic & neural time-series data via OLS")

        // Batch High-Throughput Decoding
        .def("decode_batch", [](KalmanFilter2D& kf,
                                py::array_t<double, py::array::c_style | py::array::forcecast> obs,
                                bool steady_state) {
            py::buffer_info buf = obs.request();
            if (buf.ndim != 2) {
                throw std::invalid_argument("Expected 2D array (T x obs_dim) for decode_batch");
            }
            size_t T = static_cast<size_t>(buf.shape[0]);
            size_t N = static_cast<size_t>(buf.shape[1]);
            const double* ptr = static_cast<const double*>(buf.ptr);

            py::array_t<double> result({static_cast<py::ssize_t>(T), static_cast<py::ssize_t>(2)});
            py::buffer_info res_buf = result.request();
            double* out_ptr = static_cast<double*>(res_buf.ptr);

            for (size_t t = 0; t < T; ++t) {
                std::vector<double> z_raw(ptr + t * N, ptr + (t + 1) * N);
                Vector z(z_raw);
                Vector v = steady_state ? kf.step_steady_state(z) : kf.step(z);
                out_ptr[t * 2 + 0] = v[0];
                out_ptr[t * 2 + 1] = v[1];
            }
            return result;
        }, py::arg("neural_observations"), py::arg("steady_state") = false,
           "High-throughput batch decoding of (T x N) neural array, returning (T x 2) decoded velocity")

        .def("__repr__", [](const KalmanFilter2D& kf) {
            auto v = kf.velocity();
            auto p = kf.position();
            std::ostringstream oss;
            oss << "<KalmanFilter2D velocity=(" << v.first << ", " << v.second 
                << ") position=(" << p.first << ", " << p.second << ")>";
            return oss.str();
        });
}
