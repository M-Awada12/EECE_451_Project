import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return Expanded(
      child: Container(
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
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
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
                      Flexible(
                        child: CustomBox(
                            number: networkType, label: 'Network Type'),
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: CustomBox(
                            number: signalPower, label: 'Signal Power (dBm)'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: CustomBox(number: sinr, label: 'SINR/SNR (dB)'),
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: CustomBox(
                            number: frequencyBand,
                            label: 'Frequency Band (MHz)'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: CustomBox(number: operator, label: 'Operator'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
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
      ),
    );
  }
}