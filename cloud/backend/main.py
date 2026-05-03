import math
import random
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List
import os

app = FastAPI(title="NeuroPilot Cloud API")

# Mount static files for the frontend
frontend_path = os.path.join(os.path.dirname(__file__), "..", "frontend")
app.mount("/dashboard", StaticFiles(directory=frontend_path, html=True), name="frontend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class SessionMetric(BaseModel):
    timestamp: float
    time_to_target: float
    overshoot: float
    bit_rate: float

class SessionData(BaseModel):
    session_id: str
    duration_minutes: int
    metrics: List[SessionMetric]

@app.get("/api/session/fatigue")
async def get_fatigue_data():
    # Generate mock data for a 20-minute session
    duration_min = 20
    trials_per_min = 12
    total_trials = duration_min * trials_per_min
    
    metrics = []
    
    # Base values
    base_bps = 4.8
    base_ttt = 850.0  # ms
    base_overshoot = 15.0
    
    for i in range(total_trials):
        # Progress from 0.0 to 1.0
        progress = i / total_trials
        
        # Simulate decay and fatigue
        # Bit-rate decays exponentially
        fatigue_factor = math.exp(-progress * 0.8) 
        bit_rate = base_bps * fatigue_factor + random.uniform(-0.2, 0.2)
        
        # Time-to-target increases as they get tired
        ttt = base_ttt * (1 + progress * 0.5) + random.uniform(-50, 50)
        
        # Overshoot increases (less control)
        overshoot = base_overshoot * (1 + progress * 1.2) + random.uniform(-5, 5)
        
        metrics.append(SessionMetric(
            timestamp=i * (60 / trials_per_min),
            time_to_target=max(0, ttt),
            overshoot=max(0, overshoot),
            bit_rate=max(0, bit_rate)
        ))
        
    return SessionData(
        session_id="NP-2026-04-28-FATIGUE",
        duration_minutes=duration_min,
        metrics=metrics
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
