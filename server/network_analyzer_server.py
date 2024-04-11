from fastapi import FastAPI, Query, Request, WebSocket
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import uvicorn
from pymongo import MongoClient
from datetime import datetime
from collections import defaultdict
from typing import Dict
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

connected_devices: Dict[str, bool] = {}
devices_ip: Dict[str, str] = {}
client = MongoClient("mongodb+srv://mha112:WKLY7YElcA5kHI9L@cluster0.7jh2wfc.mongodb.net/")
db = client["Network_Analyzer"]
collection = db["User Connection Data"]
initialized = False

def get_unique_mac_addresses():
  unique_mac_addresses = collection.distinct("macAddress")
  for mac_address in unique_mac_addresses:
    connected_devices[str(mac_address)] = False
    devices_ip[str(mac_address)] = str(collection.find_one({"macAddress": str(mac_address)})['ipAddress'])

if not initialized:
    get_unique_mac_addresses()
    initialized = True

class getStatisticsData(BaseModel):
    macAddress: str

class getStatisticsDateData(BaseModel):
    macAddress: str
    startDate: str
    endDate: str

class OperatorData(BaseModel):
    operator: str
    signalPower: str
    sinr: str
    networkType: str
    frequencyBand: str
    cellId: str
    timeStamp: str
    macAddress: str
    ipAddress: str

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            user_data = data.split(',')
            if len(user_data) == 2:
                mac, ip = user_data
                if mac not in connected_devices:
                    connected_devices[mac] = {}
                connected_devices[mac] = True
                devices_ip[mac] = ip
    except Exception as e:
        print(f"Connection closed: {e}")
    finally:
        for mac in connected_devices.keys():
            connected_devices[mac] = False

@app.get("/devices")
async def get_devices():
    devices_status = {"connected_devices": connected_devices, "devices_ip": devices_ip}
    return devices_status

@app.post("/data")
async def receive_data(data: OperatorData):
    if data.signalPower != "N/A":
        timestamp_str = data.timeStamp.split()[0] + " " + data.timeStamp.split()[1] + " " + data.timeStamp.split()[2]
        timestamp = datetime.strptime(timestamp_str, "%d %b %Y")

        data_dict = data.dict()
        data_dict['timeStamp'] = timestamp

        collection.insert_one(data_dict)

        return {"message": "Data received successfully"}
    else:
        return {"message": "Signal power is N/A, data not inserted"}

@app.post("/statistics")
async def get_data(data: getStatisticsData):
    results = []
    cursor = collection.find({"macAddress": data.macAddress})
    for document in cursor:
        document['_id'] = str(document['_id'])
        results.append(document)
    metrics = calculate_metrics(results, data.macAddress)
    return metrics

@app.post("/statisticsDate")
async def get_data(data: getStatisticsDateData):
    results = []
    print(data.startDate)
    
    start_date = datetime.strptime(data.startDate, "%Y-%m-%d %H:%M:%S.%f")
    end_date = datetime.strptime(data.endDate, "%Y-%m-%d %H:%M:%S.%f")
    
    cursor = collection.find({
        "macAddress": data.macAddress,
        "timeStamp": {
            "$gte": start_date,
            "$lte": end_date
        }
    })
    
    for document in cursor:
        document['_id'] = str(document['_id'])
        results.append(document)
    
    metrics = calculate_metrics(results, data.macAddress)
    return metrics

def calculate_metrics(data, mac_address):
    operator_count = defaultdict(int)
    network_type_count = defaultdict(int)
    signal_power_sum = defaultdict(float)
    snr_sum = defaultdict(float)
    device_signal_power_sum = 0
    total_records = 0

    for record in data:
        if record["macAddress"] == mac_address:
            total_records += 1
            operator_count[record["operator"]] += 1
            network_type_count[record["networkType"]] += 1
            signal_power_sum[record["networkType"]] += float(record["signalPower"])
            device_signal_power_sum += float(record["signalPower"])
            if "sinr" in record:
                snr_sum[record["networkType"]] += float(record["sinr"])

    if total_records == 0:
        return {
            "Average connectivity time per operator": {},
            "Average connectivity time per network type": {},
            "Average Signal Power per network type": {},
            "Average Signal power for the device": 0.00,
            "Average SNR/SINR per network type": {}
        }

    average_connectivity_time_per_operator = {operator: round((count / total_records) * 100, 2) for operator, count in operator_count.items()}
    average_connectivity_time_per_network_type = {network_type: round((count / total_records) * 100, 2) for network_type, count in network_type_count.items()}
    average_signal_power_per_network_type = {network_type: round((signal_power_sum[network_type] / network_type_count[network_type]), 2) for network_type in signal_power_sum}
    average_signal_power_for_device = round(device_signal_power_sum / total_records, 2)
    average_snr_per_network_type = {network_type: round((snr_sum[network_type] / network_type_count[network_type]), 2) for network_type in snr_sum if network_type in snr_sum}

    return {
        "Average connectivity time per operator": average_connectivity_time_per_operator,
        "Average connectivity time per network type": average_connectivity_time_per_network_type,
        "Average Signal Power per network type": average_signal_power_per_network_type,
        "Average Signal power for the device": average_signal_power_for_device,
        "Average SNR/SINR per network type": average_snr_per_network_type
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
