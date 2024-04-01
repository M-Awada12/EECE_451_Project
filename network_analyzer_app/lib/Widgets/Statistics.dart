import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class StatisticData {
  final Map<String, dynamic> connectivityTimePerOperator;
  final Map<String, dynamic> connectivityTimePerNetworkType;
  final Map<String, dynamic> signalPowerPerNetworkType;
  final double signalPowerForDevice;
  final Map<String, dynamic> snrPerNetworkType;

  StatisticData({
    required this.connectivityTimePerOperator,
    required this.connectivityTimePerNetworkType,
    required this.signalPowerPerNetworkType,
    required this.signalPowerForDevice,
    required this.snrPerNetworkType,
  });

  factory StatisticData.fromJson(Map<String, dynamic> json) {
    return StatisticData(
      connectivityTimePerOperator:
          json['Average connectivity time per operator'],
      connectivityTimePerNetworkType:
          json['Average connectivity time per network type'],
      signalPowerPerNetworkType: json['Average Signal Power per network type'],
      signalPowerForDevice: json['Average Signal power for the device'],
      snrPerNetworkType: json['Average SNR/SINR per network type'],
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://192.168.1.8:8000/statistics';

  static Future<StatisticData> fetchData(Map<dynamic, dynamic> data) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print(json.decode(response.body));
      return StatisticData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }
}

class Statistics extends StatefulWidget {
  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  late Future<StatisticData> futureData = Future.value(StatisticData(
    connectivityTimePerOperator: {},
    connectivityTimePerNetworkType: {},
    signalPowerPerNetworkType: {},
    signalPowerForDevice: 0.0,
    snrPerNetworkType: {},
  ));
  static const platform = const MethodChannel('telephony_channel');

  String? MACAddress;
  String error = '';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
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
        MACAddress = result['macAddress'];
        error = '';
        futureData = ApiService.fetchData(result);
      });

      print('MAC Address: $MACAddress');
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<StatisticData>(
                future: futureData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 400.0, 16.0, 10),
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    final data = snapshot.data!;
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 50.0, 16.0, 10),
                          child: _buildChart(data.connectivityTimePerOperator,
                              'Connectivity Time per Operator (%)'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 10),
                          child: _buildChart(
                              data.connectivityTimePerNetworkType,
                              'Connectivity Time per Network Type (%)'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 10),
                          child: _buildChart(data.signalPowerPerNetworkType,
                              'Signal Power per Network Type (dBm)'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 10),
                          child: _buildChart(data.snrPerNetworkType,
                              'SNR/SINR per Network Type (dB)'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 10),
                          child:
                              _buildSignalPowerChart(data.signalPowerForDevice),
                        ),
                      ],
                    );
                  } else {
                    return Text('No Data Available');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> data, String title) {
    List<charts.Series<dynamic, String>> seriesList = [
      charts.Series<dynamic, String>(
        id: title,
        domainFn: (dynamic entry, _) => entry['label'],
        measureFn: (dynamic entry, _) => entry['value'],
        data: data.entries
            .map((e) => {'label': e.key, 'value': e.value})
            .toList(),
        labelAccessorFn: (dynamic entry, _) => '${entry['value']}',
      )
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.blue, width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.0),
          Container(
            height: 300,
            child: charts.BarChart(
              seriesList,
              animate: true,
              vertical: false,
              barRendererDecorator: new charts.BarLabelDecorator<String>(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalPowerChart(double signalPower) {
    final List<charts.Series<dynamic, String>> seriesList = [
      charts.Series<dynamic, String>(
        id: 'Signal Power',
        domainFn: (_, __) => 'Signal Power',
        measureFn: (dynamic _, __) => signalPower,
        data: [
          {'value': signalPower}
        ],
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        labelAccessorFn: (dynamic _, __) => '${signalPower.toStringAsFixed(2)}',
      )
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 10),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.blue, width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            'Average Signal Power for Device (dBm)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.0),
          Container(
            height: 150,
            child: charts.BarChart(
              seriesList,
              animate: true,
              barRendererDecorator:
                  new charts.BarLabelDecorator<String>(), // Add decorator
            ),
          ),
        ],
      ),
    );
  }
}
