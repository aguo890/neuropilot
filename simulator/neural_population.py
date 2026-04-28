import numpy as np

class MotorCortexSimulator:
    """
    MVP Population Model for Motor Cortex.
    Uses a direct cosine-tuning algorithm to map 2D movement vectors to firing rates.
    """
    def __init__(self, num_neurons: int = 100):
        self.num_neurons = num_neurons
        
        # Assign random 2D preferred directions (unit vectors) to each neuron
        theta = np.random.uniform(0, np.pi * 2, num_neurons)
        self.preferred_directions = np.column_stack((np.cos(theta), np.sin(theta)))
        
        # Intrinsic biological parameters
        self.baseline_rates = np.random.uniform(5.0, 15.0, num_neurons)
        self.modulation_depths = np.random.uniform(10.0, 30.0, num_neurons)

    def step(self, movement_vector: np.ndarray, dt: float = 0.01) -> np.ndarray:
        """
        Simulate a time step given a 2D movement intention vector.
        Returns the array of spike counts for each neuron in this bin.
        """
        norm = np.linalg.norm(movement_vector)
        if norm > 0:
            movement_dir = movement_vector / norm
        else:
            movement_dir = np.zeros(2)

        # Calculate cosine tuning (dot product of preferred direction and current movement)
        cosine_tuning = np.dot(self.preferred_directions, movement_dir)
        
        # Calculate instantaneous firing rates with rectification (no negative rates)
        expected_rates = self.baseline_rates + (self.modulation_depths * cosine_tuning * norm)
        expected_rates = np.maximum(0, expected_rates)
        
        # Simulate discrete spikes for the dt bin using Poisson noise
        spikes = np.random.poisson(expected_rates * dt)
        
        return spikes
