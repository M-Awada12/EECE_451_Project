import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = const MethodChannel('telephony_channel');

  String operator = '';
  String signalPower = '';
  String sinr = '';
  String networkType = '';
  String frequencyBand = '';
  String cellId = '';
  String timeStamp = '';
  String error = '';

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
        error = '';
      });

      print('Operator: $operator');
      print('Signal Power: $signalPower dBm');
      print('SINR/SNR: $sinr dB');
      print('Network Type: $networkType');
      print('Frequency Band: $frequencyBand');
      print('Cell ID: $cellId');
      print('Time Stamp: $timeStamp');
    } on PlatformException catch (e) {
      setState(() {
        error = "Failed to get telephony info: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Network Analyzer'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                InfoTile(label: 'Operator', value: operator),
                InfoTile(label: 'Signal Power', value: '$signalPower dBm'),
                InfoTile(label: 'SINR/SNR', value: '$sinr dB'),
                InfoTile(label: 'Network Type', value: networkType),
                InfoTile(label: 'Frequency Band', value: '$frequencyBand MHz'),
                InfoTile(label: 'Cell ID', value: cellId),
                InfoTile(label: 'Time Stamp', value: timeStamp),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
