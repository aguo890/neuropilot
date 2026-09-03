// =============================================================================
// AI CONTEXT & DOCUMENTATION
// Phase: 3 (NeuroPilot Core - Task 3.3)
// Purpose: Objective-C wrapper exposing C++ KalmanFilter2D to Swift.
// Design: Clean Cocoa interface using CGPoint, NSArray<NSNumber *>, and ARC.
// Downstream: Used in DashboardViewModel to decode raw spike trains into cursor velocity.
// =============================================================================

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface NPKalmanFilterDecoder : NSObject

- (instancetype)initWithStateDim:(NSInteger)stateDim obsDim:(NSInteger)obsDim dt:(double)dt;
- (instancetype)init;

- (void)reset;
- (CGPoint)stepWithSpikeIDs:(NSArray<NSNumber *> *)spikeIDs;
- (CGPoint)stepWithNeuralObservations:(NSArray<NSNumber *> *)observations;
- (CGPoint)velocity;
- (CGPoint)position;
- (void)setPosition:(CGPoint)position;

- (void)computeSteadyState;
- (BOOL)isSteadyStateReady;
- (CGPoint)stepSteadyStateWithNeuralObservations:(NSArray<NSNumber *> *)observations;

@end

NS_ASSUME_NONNULL_END
