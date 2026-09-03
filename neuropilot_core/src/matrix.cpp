// =============================================================================
// AI CONTEXT & DOCUMENTATION
// Phase: 3 (NeuroPilot Core - Task 3.1)
// Purpose: Implementation of Matrix and Vector arithmetic, Gauss-Jordan inversion,
//          analytic 2x2/3x3 matrix inverses, and least-squares regression.
// Performance: Row-major cache-friendly inner loops (i-k-j) for matrix multiplication.
// =============================================================================

#include "neuropilot/matrix.hpp"
#include <algorithm>
#include <cmath>
#include <sstream>

namespace neuropilot {

// =============================================================================
// Vector Implementation
// =============================================================================

Vector::Vector(size_t size, double init_val)
    : data_(size, init_val) {}

Vector::Vector(std::initializer_list<double> list)
    : data_(list) {}

Vector::Vector(const std::vector<double>& data)
    : data_(data) {}

double Vector::at(size_t index) const {
    if (index >= data_.size()) {
        throw std::out_of_range("Vector index out of range: " + std::to_string(index));
    }
    return data_[index];
}

double& Vector::at(size_t index) {
    if (index >= data_.size()) {
        throw std::out_of_range("Vector index out of range: " + std::to_string(index));
    }
    return data_[index];
}

Vector Vector::operator+(const Vector& other) const {
    if (size() != other.size()) {
        throw std::invalid_argument("Vector size mismatch in addition");
    }
    Vector result(size());
    for (size_t i = 0; i < size(); ++i) {
        result[i] = data_[i] + other.data_[i];
    }
    return result;
}

Vector Vector::operator-(const Vector& other) const {
    if (size() != other.size()) {
        throw std::invalid_argument("Vector size mismatch in subtraction");
    }
    Vector result(size());
    for (size_t i = 0; i < size(); ++i) {
        result[i] = data_[i] - other.data_[i];
    }
    return result;
}

Vector Vector::operator*(double scalar) const {
    Vector result(size());
    for (size_t i = 0; i < size(); ++i) {
        result[i] = data_[i] * scalar;
    }
    return result;
}

Vector Vector::operator/(double scalar) const {
    if (std::abs(scalar) < 1e-15) {
        throw std::invalid_argument("Division by near-zero scalar");
    }
    return (*this) * (1.0 / scalar);
}

Vector& Vector::operator+=(const Vector& other) {
    if (size() != other.size()) {
        throw std::invalid_argument("Vector size mismatch in +=");
    }
    for (size_t i = 0; i < size(); ++i) {
        data_[i] += other.data_[i];
    }
    return *this;
}

Vector& Vector::operator-=(const Vector& other) {
    if (size() != other.size()) {
        throw std::invalid_argument("Vector size mismatch in -=");
    }
    for (size_t i = 0; i < size(); ++i) {
        data_[i] -= other.data_[i];
    }
    return *this;
}

Vector& Vector::operator*=(double scalar) {
    for (size_t i = 0; i < size(); ++i) {
        data_[i] *= scalar;
    }
    return *this;
}

double Vector::dot(const Vector& other) const {
    if (size() != other.size()) {
        throw std::invalid_argument("Vector size mismatch in dot product");
    }
    double sum = 0.0;
    for (size_t i = 0; i < size(); ++i) {
        sum += data_[i] * other.data_[i];
    }
    return sum;
}

double Vector::norm_sq() const {
    return dot(*this);
}

double Vector::norm() const {
    return std::sqrt(norm_sq());
}

Vector operator*(double scalar, const Vector& v) {
    return v * scalar;
}

// =============================================================================
// Matrix Implementation
// =============================================================================

Matrix::Matrix(size_t rows, size_t cols, double init_val)
    : rows_(rows), cols_(cols), data_(rows * cols, init_val) {}

Matrix::Matrix(size_t rows, size_t cols, const std::vector<double>& data)
    : rows_(rows), cols_(cols), data_(data) {
    if (data.size() != rows * cols) {
        throw std::invalid_argument("Matrix data size does not match rows * cols");
    }
}

Matrix::Matrix(std::initializer_list<std::initializer_list<double>> list) {
    rows_ = list.size();
    cols_ = rows_ > 0 ? list.begin()->size() : 0;
    data_.reserve(rows_ * cols_);
    for (const auto& row : list) {
        if (row.size() != cols_) {
            throw std::invalid_argument("Irregular initializer list in Matrix constructor");
        }
        for (double val : row) {
            data_.push_back(val);
        }
    }
}

double Matrix::at(size_t r, size_t c) const {
    if (r >= rows_ || c >= cols_) {
        throw std::out_of_range("Matrix indices out of range");
    }
    return data_[r * cols_ + c];
}

double& Matrix::at(size_t r, size_t c) {
    if (r >= rows_ || c >= cols_) {
        throw std::out_of_range("Matrix indices out of range");
    }
    return data_[r * cols_ + c];
}

Matrix Matrix::operator+(const Matrix& other) const {
    if (rows_ != other.rows_ || cols_ != other.cols_) {
        throw std::invalid_argument("Matrix dimension mismatch in addition");
    }
    Matrix result(rows_, cols_);
    for (size_t i = 0; i < data_.size(); ++i) {
        result.data_[i] = data_[i] + other.data_[i];
    }
    return result;
}

Matrix Matrix::operator-(const Matrix& other) const {
    if (rows_ != other.rows_ || cols_ != other.cols_) {
        throw std::invalid_argument("Matrix dimension mismatch in subtraction");
    }
    Matrix result(rows_, cols_);
    for (size_t i = 0; i < data_.size(); ++i) {
        result.data_[i] = data_[i] - other.data_[i];
    }
    return result;
}

// Cache-friendly i-k-j matrix multiplication
Matrix Matrix::operator*(const Matrix& other) const {
    if (cols_ != other.rows_) {
        std::ostringstream oss;
        oss << "Matrix multiplication dimension mismatch: (" 
            << rows_ << "x" << cols_ << ") * (" 
            << other.rows_ << "x" << other.cols_ << ")";
        throw std::invalid_argument(oss.str());
    }
    Matrix result(rows_, other.cols_, 0.0);
    for (size_t i = 0; i < rows_; ++i) {
        for (size_t k = 0; k < cols_; ++k) {
            double r = (*this)(i, k);
            if (std::abs(r) < 1e-16) continue;
            for (size_t j = 0; j < other.cols_; ++j) {
                result(i, j) += r * other(k, j);
            }
        }
    }
    return result;
}

Vector Matrix::operator*(const Vector& v) const {
    if (cols_ != v.size()) {
        throw std::invalid_argument("Matrix-vector multiplication dimension mismatch");
    }
    Vector result(rows_, 0.0);
    for (size_t i = 0; i < rows_; ++i) {
        double sum = 0.0;
        for (size_t j = 0; j < cols_; ++j) {
            sum += (*this)(i, j) * v[j];
        }
        result[i] = sum;
    }
    return result;
}

Matrix Matrix::operator*(double scalar) const {
    Matrix result(rows_, cols_);
    for (size_t i = 0; i < data_.size(); ++i) {
        result.data_[i] = data_[i] * scalar;
    }
    return result;
}

Matrix& Matrix::operator+=(const Matrix& other) {
    if (rows_ != other.rows_ || cols_ != other.cols_) {
        throw std::invalid_argument("Matrix dimension mismatch in +=");
    }
    for (size_t i = 0; i < data_.size(); ++i) {
        data_[i] += other.data_[i];
    }
    return *this;
}

Matrix& Matrix::operator-=(const Matrix& other) {
    if (rows_ != other.rows_ || cols_ != other.cols_) {
        throw std::invalid_argument("Matrix dimension mismatch in -=");
    }
    for (size_t i = 0; i < data_.size(); ++i) {
        data_[i] -= other.data_[i];
    }
    return *this;
}

Matrix& Matrix::operator*=(double scalar) {
    for (size_t i = 0; i < data_.size(); ++i) {
        data_[i] *= scalar;
    }
    return *this;
}

Matrix Matrix::transpose() const {
    Matrix result(cols_, rows_);
    for (size_t i = 0; i < rows_; ++i) {
        for (size_t j = 0; j < cols_; ++j) {
            result(j, i) = (*this)(i, j);
        }
    }
    return result;
}

Vector Matrix::row(size_t r) const {
    if (r >= rows_) throw std::out_of_range("Row index out of range");
    Vector result(cols_);
    for (size_t c = 0; c < cols_; ++c) {
        result[c] = (*this)(r, c);
    }
    return result;
}

Vector Matrix::col(size_t c) const {
    if (c >= cols_) throw std::out_of_range("Col index out of range");
    Vector result(rows_);
    for (size_t r = 0; r < rows_; ++r) {
        result[r] = (*this)(r, c);
    }
    return result;
}

void Matrix::set_row(size_t r, const Vector& v) {
    if (r >= rows_ || v.size() != cols_) throw std::invalid_argument("Invalid set_row parameters");
    for (size_t c = 0; c < cols_; ++c) {
        (*this)(r, c) = v[c];
    }
}

void Matrix::set_col(size_t c, const Vector& v) {
    if (c >= cols_ || v.size() != rows_) throw std::invalid_argument("Invalid set_col parameters");
    for (size_t r = 0; r < rows_; ++r) {
        (*this)(r, c) = v[r];
    }
}

Matrix Matrix::eye(size_t n) {
    Matrix result(n, n, 0.0);
    for (size_t i = 0; i < n; ++i) {
        result(i, i) = 1.0;
    }
    return result;
}

Matrix Matrix::diag(const Vector& v) {
    Matrix result(v.size(), v.size(), 0.0);
    for (size_t i = 0; i < v.size(); ++i) {
        result(i, i) = v[i];
    }
    return result;
}

Matrix Matrix::inverse_2x2() const {
    double a = (*this)(0, 0);
    double b = (*this)(0, 1);
    double c = (*this)(1, 0);
    double d = (*this)(1, 1);
    double det = a * d - b * c;
    if (std::abs(det) < 1e-15) {
        throw std::runtime_error("Matrix is singular (2x2 determinant is zero)");
    }
    double inv_det = 1.0 / det;
    return Matrix{
        { d * inv_det, -b * inv_det},
        {-c * inv_det,  a * inv_det}
    };
}

Matrix Matrix::inverse_3x3() const {
    const auto& m = *this;
    double det = m(0, 0) * (m(1, 1) * m(2, 2) - m(1, 2) * m(2, 1)) -
                 m(0, 1) * (m(1, 0) * m(2, 2) - m(1, 2) * m(2, 0)) +
                 m(0, 2) * (m(1, 0) * m(2, 1) - m(1, 1) * m(2, 0));

    if (std::abs(det) < 1e-15) {
        throw std::runtime_error("Matrix is singular (3x3 determinant is zero)");
    }

    double inv_det = 1.0 / det;
    Matrix inv(3, 3);
    inv(0, 0) = (m(1, 1) * m(2, 2) - m(1, 2) * m(2, 1)) * inv_det;
    inv(0, 1) = (m(0, 2) * m(2, 1) - m(0, 1) * m(2, 2)) * inv_det;
    inv(0, 2) = (m(0, 1) * m(1, 2) - m(0, 2) * m(1, 1)) * inv_det;
    inv(1, 0) = (m(1, 2) * m(2, 0) - m(1, 0) * m(2, 2)) * inv_det;
    inv(1, 1) = (m(0, 0) * m(2, 2) - m(0, 2) * m(2, 0)) * inv_det;
    inv(1, 2) = (m(0, 2) * m(1, 0) - m(0, 0) * m(1, 2)) * inv_det;
    inv(2, 0) = (m(1, 0) * m(2, 1) - m(1, 1) * m(2, 0)) * inv_det;
    inv(2, 1) = (m(0, 1) * m(2, 0) - m(0, 0) * m(2, 1)) * inv_det;
    inv(2, 2) = (m(0, 0) * m(1, 1) - m(0, 1) * m(1, 0)) * inv_det;
    return inv;
}

Matrix Matrix::inverse_gauss_jordan(double regularizer) const {
    size_t n = rows_;
    // Augmented matrix [A | I]
    std::vector<std::vector<double>> aug(n, std::vector<double>(2 * n, 0.0));
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            aug[i][j] = (*this)(i, j);
        }
        if (regularizer > 0.0) {
            aug[i][i] += regularizer;
        }
        aug[i][n + i] = 1.0;
    }

    // Gauss-Jordan elimination with partial pivoting
    for (size_t col = 0; col < n; ++col) {
        // Find best pivot
        size_t max_row = col;
        double max_val = std::abs(aug[col][col]);
        for (size_t r = col + 1; r < n; ++r) {
            double v = std::abs(aug[r][col]);
            if (v > max_val) {
                max_val = v;
                max_row = r;
            }
        }

        if (max_val < 1e-15) {
            throw std::runtime_error("Matrix is singular or ill-conditioned in Gauss-Jordan inversion");
        }

        // Swap rows if necessary
        if (max_row != col) {
            std::swap(aug[col], aug[max_row]);
        }

        // Scale pivot row
        double pivot = aug[col][col];
        double inv_pivot = 1.0 / pivot;
        for (size_t j = 0; j < 2 * n; ++j) {
            aug[col][j] *= inv_pivot;
        }

        // Eliminate column entries in all other rows
        for (size_t r = 0; r < n; ++r) {
            if (r != col) {
                double factor = aug[r][col];
                if (std::abs(factor) > 1e-16) {
                    for (size_t j = 0; j < 2 * n; ++j) {
                        aug[r][j] -= factor * aug[col][j];
                    }
                }
            }
        }
    }

    Matrix result(n, n);
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            result(i, j) = aug[i][n + j];
        }
    }
    return result;
}

Matrix Matrix::inverse(double regularizer) const {
    if (rows_ != cols_) {
        throw std::invalid_argument("Cannot invert non-square matrix");
    }
    if (regularizer == 0.0) {
        if (rows_ == 2) return inverse_2x2();
        if (rows_ == 3) return inverse_3x3();
    }
    return inverse_gauss_jordan(regularizer);
}

Vector Matrix::solve(const Vector& b, double regularizer) const {
    if (rows_ != cols_) {
        throw std::invalid_argument("System matrix must be square for solve()");
    }
    if (rows_ != b.size()) {
        throw std::invalid_argument("Dimension mismatch in solve(Vector)");
    }
    return inverse(regularizer) * b;
}

Matrix Matrix::solve(const Matrix& B, double regularizer) const {
    if (rows_ != cols_) {
        throw std::invalid_argument("System matrix must be square for solve()");
    }
    if (rows_ != B.rows()) {
        throw std::invalid_argument("Dimension mismatch in solve(Matrix)");
    }
    return inverse(regularizer) * B;
}

Matrix Matrix::least_squares(const Matrix& A, const Matrix& B, double ridge_lambda) {
    if (A.rows() != B.rows()) {
        throw std::invalid_argument("Row count mismatch between A and B in least_squares");
    }
    // Solve (A^T * A + lambda * I) * X = A^T * B
    Matrix At = A.transpose();
    Matrix AtA = At * A;
    if (ridge_lambda > 0.0) {
        for (size_t i = 0; i < AtA.rows(); ++i) {
            AtA(i, i) += ridge_lambda;
        }
    }
    Matrix AtB = At * B;
    return AtA.solve(AtB);
}

Matrix operator*(double scalar, const Matrix& m) {
    return m * scalar;
}

} // namespace neuropilot
