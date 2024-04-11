import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class CustomBox extends StatelessWidget {
  final String? number;
  final String? label;

  const CustomBox({
    Key? key,
    this.number,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Set the fixed height
      margin: EdgeInsets.all(8.0),
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.blue,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            number ?? '', // Display number or empty string if null
            style: TextStyle(
              fontSize: 21.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5.0),
          Center(
            child: Text(
              label ?? '', // Display label or empty string if null
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Status extends StatefulWidget {
  @override
  _StatusState createState() => _StatusState();
}

class _StatusState extends State<Status> {
  static const platform = const MethodChannel('telephony_channel');

  String? operator = '';
  String? signalPower = '';
  String? sinr = '';
  String? networkType = '';
  String? frequencyBand = '';
  String? cellId = '';
  String? timeStamp = '';
  String error = '';
  String? MACAddress = '';
  String? IPAddress = '';

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _getTelephonyInfo();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    if (await Permission.location.request().isGranted &&
        await Permission.phone.request().isGranted) {
      _getTelephonyInfo();
    } else {
      setState(() {
        error = 'Location permission is not granted.';
      });
    }
  }

  void sendData(data) async {
    final String apiUrl = 'https://four51-server.onrender.com/data';

    final response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('Data sent successfully');
    } else {
      print('Failed to send data');
    }
  }

  Future<void> _getTelephonyInfo() async {
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('getTelephonyInfo');
      setState(() {
        operator = result['operator'];
        signalPower = result['signalPower'];
        sinr = result['sinr'];
        networkType = result['networkType'];
        frequencyBand = result['frequencyBand'];
        cellId = result['cellId'];
        timeStamp = result['timeStamp'];
        MACAddress = result['macAddress'];
        IPAddress = result['ipAddress'];
        error = '';
      });

      sendData(result);
      print('Operator: $operator');
      print('Signal Power: $signalPower dBm');
      print('SINR/SNR: $sinr dB');
      print('Network Type: $networkType');
      print('Frequency Band: $frequencyBand');
      print('Cell ID: $cellId');
      print('Time Stamp: $timeStamp');
      print('MAC Address: $MACAddress');
      print('IP Address: $IPAddress');
    } on PlatformException catch (e) {
      setState(() {
        error = "Failed to get telephony info: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 191, 219, 255),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child:
                          CustomBox(number: networkType, label: 'Network Type'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomBox(
                          number: signalPower, label: 'Signal Power (dBm)'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomBox(number: sinr, label: 'SINR/SNR (dB)'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomBox(
                          number: frequencyBand, label: 'Frequency Band (MHz)'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomBox(number: operator, label: 'Operator'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomBox(number: cellId, label: 'Cell ID'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: CustomBox(number: timeStamp, label: 'Time Stamp'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}