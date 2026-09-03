// =============================================================================
// AI CONTEXT & DOCUMENTATION
// Phase: 3 (NeuroPilot Core - Task 3.3)
// Purpose: Objective-C++ implementation bridging C++ KalmanFilter2D to Swift.
// Memory Safety: Uses std::unique_ptr for RAII lifecycle management of C++ instance.
// Performance: Ingests NSArray spike IDs and outputs CGPoint 2D velocity directly.
// =============================================================================

#import "NPKalmanFilterDecoder.h"
#include "neuropilot/kalman_filter.hpp"
#include <memory>
#include <vector>

@implementation NPKalmanFilterDecoder {
    std::unique_ptr<neuropilot::KalmanFilter2D> _cppFilter;
}

- (instancetype)initWithStateDim:(NSInteger)stateDim obsDim:(NSInteger)obsDim dt:(double)dt {
    self = [super init];
    if (self) {
        _cppFilter = std::make_unique<neuropilot::KalmanFilter2D>(
            static_cast<size_t>(stateDim),
            static_cast<size_t>(obsDim),
            dt
        );
    }
    return self;
}

- (instancetype)init {
    return [self initWithStateDim:2 obsDim:100 dt:0.01];
}

- (void)reset {
    if (_cppFilter) {
        _cppFilter->reset();
    }
}

- (CGPoint)stepWithSpikeIDs:(NSArray<NSNumber *> *)spikeIDs {
    if (!_cppFilter) return CGPointZero;

    std::vector<int> ids;
    ids.reserve(spikeIDs.count);
    for (NSNumber *num in spikeIDs) {
        ids.push_back(num.intValue);
    }

    neuropilot::Vector out = _cppFilter->step_spikes(ids);
    double vx = out.size() > 0 ? out[0] : 0.0;
    double vy = out.size() > 1 ? out[1] : 0.0;
    return CGPointMake(vx, vy);
}

- (CGPoint)stepWithNeuralObservations:(NSArray<NSNumber *> *)observations {
    if (!_cppFilter) return CGPointZero;

    std::vector<double> z;
    z.reserve(observations.count);
    for (NSNumber *num in observations) {
        z.push_back(num.doubleValue);
    }

    neuropilot::Vector out = _cppFilter->step(neuropilot::Vector(z));
    double vx = out.size() > 0 ? out[0] : 0.0;
    double vy = out.size() > 1 ? out[1] : 0.0;
    return CGPointMake(vx, vy);
}

- (CGPoint)velocity {
    if (!_cppFilter) return CGPointZero;
    auto v = _cppFilter->velocity();
    return CGPointMake(v.first, v.second);
}

- (CGPoint)position {
    if (!_cppFilter) return CGPointZero;
    auto p = _cppFilter->position();
    return CGPointMake(p.first, p.second);
}

- (void)setPosition:(CGPoint)position {
    if (_cppFilter) {
        _cppFilter->set_position(position.x, position.y);
    }
}

- (void)computeSteadyState {
    if (_cppFilter) {
        _cppFilter->compute_steady_state();
    }
}

- (BOOL)isSteadyStateReady {
    return _cppFilter ? _cppFilter->is_steady_state_ready() : NO;
}

- (CGPoint)stepSteadyStateWithNeuralObservations:(NSArray<NSNumber *> *)observations {
    if (!_cppFilter) return CGPointZero;

    std::vector<double> z;
    z.reserve(observations.count);
    for (NSNumber *num in observations) {
        z.push_back(num.doubleValue);
    }

    neuropilot::Vector out = _cppFilter->step_steady_state(neuropilot::Vector(z));
    double vx = out.size() > 0 ? out[0] : 0.0;
    double vy = out.size() > 1 ? out[1] : 0.0;
    return CGPointMake(vx, vy);
}

@end
