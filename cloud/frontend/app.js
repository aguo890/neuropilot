document.addEventListener('DOMContentLoaded', () => {
    // Initialize Lucide icons
    lucide.createIcons();

    const API_URL = 'http://localhost:8000/api/session/fatigue';

    async function fetchData() {
        try {
            const response = await fetch(API_URL);
            const data = await response.json();
            updateUI(data);
            renderCharts(data);
        } catch (error) {
            console.error('Error fetching fatigue data:', error);
            // Show mock error state or fallback
        }
    }

    function updateUI(data) {
        const metrics = data.metrics;
        const avgTTT = metrics.reduce((acc, m) => acc + m.time_to_target, 0) / metrics.length;
        const avgOvershoot = metrics.reduce((acc, m) => acc + m.overshoot, 0) / metrics.length;
        const avgBPS = metrics.reduce((acc, m) => acc + m.bit_rate, 0) / metrics.length;

        document.getElementById('avg-ttt').textContent = Math.round(avgTTT);
        document.getElementById('avg-overshoot').textContent = avgOvershoot.toFixed(1);
        document.getElementById('avg-bps').textContent = avgBPS.toFixed(2);
    }

    function renderCharts(data) {
        const ctxBps = document.getElementById('bps-chart').getContext('2d');
        const ctxScatter = document.getElementById('scatter-chart').getContext('2d');

        const labels = data.metrics.map(m => Math.round(m.timestamp / 60) + 'm');
        const bpsData = data.metrics.map(m => m.bit_rate);
        const tttData = data.metrics.map(m => m.time_to_target);
        const overshootData = data.metrics.map(m => m.overshoot);

        // Chart.js Default Configurations
        Chart.defaults.color = '#94a3b8';
        Chart.defaults.font.family = "'Inter', sans-serif";

        // Bit-Rate Decay Chart
        new Chart(ctxBps, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Bit-Rate (BPS)',
                    data: bpsData,
                    borderColor: '#3b82f6',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    x: {
                        grid: { display: false },
                        ticks: { maxRotation: 0, autoSkip: true, maxTicksLimit: 10 }
                    },
                    y: {
                        grid: { color: 'rgba(255, 255, 255, 0.05)' },
                        beginAtZero: false,
                        suggestedMax: 5
                    }
                }
            }
        });

        // Scatter Chart (TTT vs Overshoot)
        new Chart(ctxScatter, {
            type: 'scatter',
            data: {
                datasets: [{
                    label: 'Trials',
                    data: data.metrics.map(m => ({ x: m.time_to_target, y: m.overshoot })),
                    backgroundColor: (context) => {
                        const index = context.dataIndex;
                        const progress = index / data.metrics.length;
                        return progress > 0.6 ? 'rgba(239, 68, 68, 0.6)' : 'rgba(6, 182, 212, 0.6)';
                    },
                    pointRadius: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    x: {
                        title: { display: true, text: 'Time-to-Target (ms)' },
                        grid: { color: 'rgba(255, 255, 255, 0.05)' }
                    },
                    y: {
                        title: { display: true, text: 'Overshoot (px)' },
                        grid: { color: 'rgba(255, 255, 255, 0.05)' }
                    }
                }
            }
        });
    }

    fetchData();
});
