import asyncio
import json
import numpy as np
import logging
from neural_population import MotorCortexSimulator

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
                
            data = {
                "timestamp": t,
                "kinematics": simulated_movement.tolist(),
                "spikes": spike_ids
            }
            
            # Serialize to JSON and send with newline delimiter
            payload = json.dumps(data) + "\n"
            writer.write(payload.encode('utf-8'))
            await writer.drain()
            
            # Maintain a 100 Hz update loop
            await asyncio.sleep(dt)
            
    except ConnectionResetError:
        logging.info(f"Client {addr} disconnected.")
    except asyncio.CancelledError:
        pass
    except Exception as e:
        logging.error(f"Error serving client {addr}: {e}")
    finally:
        writer.close()
        await writer.wait_closed()
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
