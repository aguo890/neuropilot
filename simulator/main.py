import asyncio
import json
import numpy as np
import logging
from neural_population import MotorCortexSimulator

# =============================================================================
# AI CONTEXT & DOCUMENTATION
# Phase: 1 (Neural Simulator MVP)
# Purpose: TCP server that streams JSON neural data to the upcoming Swift macOS client.
# Network: Runs on 127.0.0.1:9000 at 100 Hz (10ms updates).
# Data Format: newline-delimited JSON stream.
# Example payload: {"timestamp": 12.34, "kinematics": [0.5, -0.2], "spikes": [5, 12, 12, 45, 99]}
# Note: The 'spikes' field is a flat list of neuron IDs that fired. If a neuron fires N times, its ID is appended N times.
# =============================================================================

# Minimal setup for practical visibility
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

async def handle_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
    addr = writer.get_extra_info('peername')
    logging.info(f"Client connected from {addr}")
    
    # Initialize the neural population
    simulator = MotorCortexSimulator(num_neurons=100)
    
    try:
        while True:
            # MVP: Auto-generate a figure-8 2D movement intention
            t = asyncio.get_event_loop().time()
            simulated_movement = np.array([np.sin(t), np.sin(2 * t)])
            
            # Step the neural model forward by 10ms
            dt = 0.01
            spikes = simulator.step(simulated_movement, dt=dt)
            
            # Construct flat list of spike IDs (allowing duplicates if a neuron fires > 1 time)
            spike_ids = []
            for i, count in enumerate(spikes):
                spike_ids.extend([i] * count)
                
            # Confidence: Simulated decoder confidence (tends to dip during high-velocity changes)
            mag = np.linalg.norm(simulated_movement)
            confidence = max(0.4, 1.0 - (mag * 0.2) + np.random.uniform(-0.05, 0.05))
            
            # Artifact injection: 1% chance of a high-voltage muscle artifact
            is_artifact = np.random.random() < 0.01
            
            data = {
                "timestamp": t,
                "kinematics": simulated_movement.tolist(),
                "spikes": spike_ids,
                "confidence": float(confidence),
                "is_artifact": is_artifact
            }
            
            # Serialize to JSON and send with newline delimiter
            payload = json.dumps(data) + "\n"
            writer.write(payload.encode('utf-8'))
            await writer.drain()
            
            # Maintain a 100 Hz update loop
            await asyncio.sleep(dt)
            
    except ConnectionError:
        logging.info(f"Client {addr} disconnected.")
    except asyncio.CancelledError:
        pass
    except Exception as e:
        logging.error(f"Error serving client {addr}: {e}")
    finally:
        writer.close()
        try:
            await writer.wait_closed()
        except ConnectionError:
            pass
        logging.info(f"Connection to {addr} closed.")

async def main():
    host = '127.0.0.1'
    port = 9000
    
    # Direct, zero-abstraction TCP server
    server = await asyncio.start_server(handle_client, host, port)
    
    addr = server.sockets[0].getsockname()
    logging.info(f"Neural Simulator MVP streaming on {addr}")
    
    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Simulator stopped by user.")
