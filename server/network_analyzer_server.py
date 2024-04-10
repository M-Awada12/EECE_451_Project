from fastapi import FastAPI, Query
from pydantic import BaseModel
import uvicorn
from pymongo import MongoClient
from datetime import datetime
from collections import defaultdict

app = FastAPI()

client = MongoClient("mongodb+srv://mha112:WKLY7YElcA5kHI9L@cluster0.7jh2wfc.mongodb.net/")
db = client["Network_Analyzer"]
collection = db["User Connection Data"]

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

@app.post("/data")
async def receive_data(data: OperatorData):
    collection.insert_one(data.dict())
    return {"message": "Data received successfully"}

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
    start_date = datetime.strptime(data.startDate, "%Y-%m-%d %H:%M:%S.%f")
    end_date = datetime.strptime(data.endDate, "%Y-%m-%d %H:%M:%S.%f")
    cursor = collection.find({
        "mac_address": data.macAddress,
        "timeStamp": {"$gte": start_date, "$lte": end_date}
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
