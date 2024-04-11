import React, { useState, useEffect } from "react";
import { useNavigate } from 'react-router-dom';
import "./ConnectionTable.css";
import axios from 'axios';

function ConnectionTable() {
  const [data, setData] = useState({});
  const navigate = useNavigate();

  const fetchData = async () => {
    try {
      const response = await axios.get('https://four51-server.onrender.com/devices');
      console.log(response);
      setData(response.data);
    } catch (error) {
      console.log(error);
    }
  };

  useEffect(() => {
    fetchData();

    const interval = setInterval(fetchData, 1000);

    return () => clearInterval(interval);
  }, []);

  function getConnected() {
    let returnValue = 0;
    Object.keys(data.connected_devices).map((key) => {
      if (data.connected_devices[key] == true) {
        returnValue++;
      }
    })
    return returnValue;
  }

  return (
    <div className="connection-table-container">
      {Object.keys(data).length === 0 ? (
        null
      ) : (
        <div className="container">
          <label className="label">Total Devices: {Object.keys(data.connected_devices).length}</label>
          <label className="label">Connected Devices: {getConnected()}</label>
        </div>
      )}
      <div className="awesome-container">
        <div className="center-container">
          {Object.keys(data).length === 0 ? (
            <div className="loading-spinner"></div>
          ) : (
            <table className="connected-devices-table">
              <thead>
                <tr>
                  <th className="table-header">MAC Address</th>
                  <th className="table-header">IP Address</th>
                  <th className="table-header">Status</th>
                  <th className="table-header">Action</th>
                </tr>
              </thead>
              <tbody>
                {Object.keys(data.connected_devices).map((deviceId) => (
                  <tr key={deviceId}>
                    <td className="table-data">{deviceId}</td>
                    <td className="table-data">{data.devices_ip[deviceId]}</td>
                    <td className="table-data">
                      <span
                        className={
                          data.connected_devices[deviceId]
                            ? "connected-status"
                            : "disconnected-status"
                        }
                      >
                        {data.connected_devices[deviceId] ? "Connected" : "Disconnected"}
                      </span>
                    </td>
                    <td className="table-data">
                      <button className="view-details-button" onClick={() => navigate(`/details/${deviceId}`)}>View Details</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}

export default ConnectionTable;