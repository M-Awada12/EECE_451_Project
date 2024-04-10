import React, { useState, useEffect, useRef } from 'react';
import Chart from 'chart.js/auto';

const NetworkMetrics = ({ data }) => {

    const chartsRef = useRef({});

    useEffect(() => {
        const generateCharts = () => {
            const newCharts = {};
            for (const key in data) {
                const ctx = document.getElementById(key);
                if (ctx) {
                    if (chartsRef.current[key]) {
                        chartsRef.current[key].destroy();
                    }
                    if (typeof data[key] === 'object') {
                        newCharts[key] = new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: Object.keys(data[key]),
                                datasets: [{
                                    label: key,
                                    data: Object.values(data[key]),
                                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                                    borderColor: 'rgba(54, 162, 235, 1)',
                                    borderWidth: 1
                                }]
                            },
                            options: {
                                scales: {
                                    y: {
                                        beginAtZero: true,
                                        ticks: {
                                            callback: function (value) {
                                                return value; // Display exact value
                                            }
                                        }
                                    }
                                },
                                plugins: {
                                    tooltip: {
                                        callbacks: {
                                            label: function (context) {
                                                var label = context.dataset.label || '';
                                                if (label) {
                                                    label += ': ';
                                                }
                                                if (context.parsed.y !== null) {
                                                    label += context.parsed.y;
                                                }
                                                return label;
                                            }
                                        }
                                    }
                                }
                            }
                        });
                    } else {
                        newCharts[key] = new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: [key],
                                datasets: [{
                                    label: key,
                                    data: [data[key]],
                                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                                    borderColor: 'rgba(54, 162, 235, 1)',
                                    borderWidth: 1
                                }]
                            },
                            options: {
                                plugins: {
                                    tooltip: {
                                        callbacks: {
                                            label: function (context) {
                                                return context.dataset.data[0];
                                            }
                                        }
                                    }
                                }
                            }
                        });
                    }
                }
            }
            chartsRef.current = newCharts;
        };

        generateCharts();

        return () => {
            // Clean up code
            for (const key in chartsRef.current) {
                if (chartsRef.current[key]) {
                    chartsRef.current[key].destroy();
                }
            }
        };
    }, [data]);

    return (
        <div>
            {Object.keys(data).map((key, index) => (
                <div key={index}>
                    <h3>{key}</h3>
                    <canvas id={key} width="400" height="200"></canvas>
                </div>
            ))}
        </div>
    );
};

export default NetworkMetrics;