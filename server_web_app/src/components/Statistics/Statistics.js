import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from 'react-router-dom';
import "./Statistics.css";
import axios from 'axios';
import NetworkMetrics from "./NetworkMetrics";

function Statistics() {
    const { deviceId } = useParams();
    const [data, setData] = useState({});
    const [dateRange, setDateRange] = useState({
        startDate: null,
        endDate: null,
    });
    const [showDatePickers, setShowDatePickers] = useState(false);
    const [pickerType, setPickerType] = useState('Overall');

    const fetchData = async () => {
        if (!showDatePickers) {
            try {
                let dataToSend = { macAddress: deviceId };
                const response = await axios.post('https://four51-server.onrender.com/statistics', dataToSend);
                console.log(response.data);
                setData(response.data);
            } catch (error) {
                console.log(error);
            }
        }
        else {
            if (dateRange['startDate'] != null && dateRange['endDate'] != null) {
                try {
                    let dataToSend = { macAddress: deviceId, startDate: String(dateRange['startDate']) + ' 00:00:00.000', endDate: String(dateRange['endDate']) + ' 00:00:00.000' };
                    console.log(dataToSend)
                    const response = await axios.post('https://four51-server.onrender.com/statisticsDate', dataToSend);
                    console.log(response.data);
                    setData(response.data);
                } catch (error) {
                    console.log(error);
                }
            }
        }
    };

    useEffect(() => {
        fetchData();
    }, [showDatePickers, dateRange]);

    const handlePickerChange = (event) => {
        const { value } = event.target;
        setPickerType(value);
        if (value === 'Specific Dates') {
            setData({});
            setShowDatePickers(true);
        } else {
            setData({});
            setShowDatePickers(false);
        }
    };

    const handleStartDateChange = (event) => {
        setDateRange({ ...dateRange, startDate: event.target.value });
    };

    const handleEndDateChange = (event) => {
        setDateRange({ ...dateRange, endDate: event.target.value });
    };

    return (
        <div className="connection-table-container">
            {console.log(dateRange)}
            <div className="blue-line" />
            <div style={{ 'marginTop': '20px' }} className="date-range-picker-container">
                <select className="picker-select" value={pickerType} onChange={handlePickerChange}>
                    <option value="Overall">Overall</option>
                    <option value="Specific Dates">Specific Dates</option>
                </select>
                {showDatePickers && (
                    <div className="date-pickers">
                        <label className="date-label" htmlFor="startDate">Start Date:</label>
                        <input
                            type="date"
                            id="startDate"
                            value={dateRange.startDate}
                            onChange={handleStartDateChange}
                            className="date-input"
                            style={{ 'marginRight': '20px' }}
                        />
                        <label className="date-label" htmlFor="endDate">End Date:</label>
                        <input
                            type="date"
                            id="endDate"
                            value={dateRange.endDate}
                            onChange={handleEndDateChange}
                            className="date-input"
                        />
                    </div>
                )}
            </div>
            <div className="awesome-container">
                <div className="center-container">
                    {Object.keys(data).length === 0 ? (
                        <div className="loading-spinner"></div>
                    ) : (
                        <div>
                            <NetworkMetrics data={data} />
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

export default Statistics;