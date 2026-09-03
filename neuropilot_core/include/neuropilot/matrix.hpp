#pragma once

// =============================================================================
// AI CONTEXT & DOCUMENTATION
// Phase: 3 (NeuroPilot Core - Task 3.1)
// Purpose: Zero-dependency, cache-friendly linear algebra engine for BCI state estimation.
// Design: Contiguous row-major storage for ultra-fast cache line utilization.
// Downstream: Used directly by KalmanFilter2D for real-time 100 Hz velocity decoding.
// =============================================================================

#include <vector>
#include <initializer_list>
#include <cstddef>
#include <stdexcept>
#include <cmath>
#include <string>

namespace neuropilot {

class Matrix;

class Vector {
public:
    Vector() = default;
    explicit Vector(size_t size, double init_val = 0.0);
    Vector(std::initializer_list<double> list);
    Vector(const std::vector<double>& data);

    size_t size() const { return data_.size(); }
    bool empty() const { return data_.empty(); }
    const double* data() const { return data_.data(); }
    double* data() { return data_.data(); }

    double operator[](size_t index) const { return data_[index]; }
    double& operator[](size_t index) { return data_[index]; }
    double at(size_t index) const;
    double& at(size_t index);

    Vector operator+(const Vector& other) const;
    Vector operator-(const Vector& other) const;
    Vector operator*(double scalar) const;
    Vector operator/(double scalar) const;

    Vector& operator+=(const Vector& other);
    Vector& operator-=(const Vector& other);
    Vector& operator*=(double scalar);

    double dot(const Vector& other) const;
    double norm_sq() const;
    double norm() const;

    const std::vector<double>& raw() const { return data_; }
    std::vector<double>& raw() { return data_; }

    static Vector zeros(size_t size) { return Vector(size, 0.0); }
    static Vector ones(size_t size) { return Vector(size, 1.0); }

private:
    std::vector<double> data_;
};

Vector operator*(double scalar, const Vector& v);

class Matrix {
public:
    Matrix() : rows_(0), cols_(0) {}
    Matrix(size_t rows, size_t cols, double init_val = 0.0);
    Matrix(size_t rows, size_t cols, const std::vector<double>& data);
    Matrix(std::initializer_list<std::initializer_list<double>> list);

    size_t rows() const { return rows_; }
    size_t cols() const { return cols_; }
    bool empty() const { return data_.empty(); }
    const double* data() const { return data_.data(); }
    double* data() { return data_.data(); }

    double operator()(size_t r, size_t c) const { return data_[r * cols_ + c]; }
    double& operator()(size_t r, size_t c) { return data_[r * cols_ + c]; }
    double at(size_t r, size_t c) const;
    double& at(size_t r, size_t c);

    Matrix operator+(const Matrix& other) const;
    Matrix operator-(const Matrix& other) const;
    Matrix operator*(const Matrix& other) const;
    Vector operator*(const Vector& v) const;
    Matrix operator*(double scalar) const;

    Matrix& operator+=(const Matrix& other);
    Matrix& operator-=(const Matrix& other);
    Matrix& operator*=(double scalar);

    Matrix transpose() const;
    Matrix inverse(double regularizer = 0.0) const;

    Vector solve(const Vector& b, double regularizer = 0.0) const;
    Matrix solve(const Matrix& B, double regularizer = 0.0) const;

    Vector row(size_t r) const;
    Vector col(size_t c) const;
    void set_row(size_t r, const Vector& v);
    void set_col(size_t c, const Vector& v);

    const std::vector<double>& raw() const { return data_; }
    std::vector<double>& raw() { return data_; }

    static Matrix zeros(size_t rows, size_t cols) { return Matrix(rows, cols, 0.0); }
    static Matrix ones(size_t rows, size_t cols) { return Matrix(rows, cols, 1.0); }
    static Matrix eye(size_t n);
    static Matrix diag(const Vector& v);

    // Ordinary Least Squares: fits X in A * X ≈ B via (A^T * A + lambda * I)^(-1) * A^T * B
    static Matrix least_squares(const Matrix& A, const Matrix& B, double ridge_lambda = 1e-6);

private:
    size_t rows_;
    size_t cols_;
    std::vector<double> data_;

    Matrix inverse_2x2() const;
    Matrix inverse_3x3() const;
    Matrix inverse_gauss_jordan(double regularizer) const;
};

Matrix operator*(double scalar, const Matrix& m);

} // namespace neuropilot
