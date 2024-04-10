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
  static const String baseUrl = 'https://four51-server.onrender.com/statistics';
  static const String dateUrl =
      'https://four51-server.onrender.com/statisticsDate';

  static Future<StatisticData> fetchData(
      Map<dynamic, dynamic> data, bool specificDateSelected) async {
    final String url = specificDateSelected ? dateUrl : baseUrl;

    final response = await http.post(
      Uri.parse(url),
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
  bool specificDateSelected = false;
  DateTime? startDate;
  DateTime? endDate;

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
      Map<dynamic, dynamic> data = {'macAddress': result['macAddress']};

      if (!specificDateSelected) {
        setState(() {
          MACAddress = result['macAddress'];
          error = '';
          print(result);
          futureData = ApiService.fetchData(result, false);
        });
      } else {
        data['startDate'] = startDate.toString();
        data['endDate'] = endDate.toString();

        setState(() {
          MACAddress = result['macAddress'];
          error = '';
          futureData = ApiService.fetchData(data, true);
        });
      }

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
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 10),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue),
                ),
                child: DropdownButton<String>(
                  value: specificDateSelected ? 'Specific date' : 'Overall',
                  onChanged: (String? newValue) {
                    setState(() {
                      specificDateSelected = newValue == 'Specific date';
                      if (!specificDateSelected ||
                          (specificDateSelected &&
                              (startDate != null && endDate != null))) {
                        _getTelephonyInfo();
                      }
                    });
                  },
                  items: <String>['Overall', 'Specific date']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (specificDateSelected) ...[
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final DateTime? pickedStartDate = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2015, 8),
                          lastDate: DateTime(2101),
                        );
                        if (pickedStartDate != null) {
                          setState(() {
                            startDate = pickedStartDate;
                            print(startDate);
                            if (specificDateSelected &&
                                (startDate != null && endDate != null)) {
                              _getTelephonyInfo();
                            }
                          });
                        }
                      },
                      child: Text('Select Start Date'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final DateTime? pickedEndDate = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2015, 8),
                          lastDate: DateTime(2101),
                        );
                        if (pickedEndDate != null) {
                          setState(() {
                            endDate = pickedEndDate;
                            print(endDate);
                            if (specificDateSelected &&
                                (startDate != null && endDate != null)) {
                              _getTelephonyInfo();
                            }
                          });
                        }
                      },
                      child: Text('Select End Date'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
              if (!specificDateSelected ||
                  (specificDateSelected &&
                      (startDate != null && endDate != null))) ...[
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
                            child: _buildSignalPowerChart(
                                data.signalPowerForDevice),
                          ),
                        ],
                      );
                    } else {
                      return Text('No Data Available');
                    }
                  },
                ),
              ] else ...[
                SizedBox(height: 200),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 82, 151, 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Please Insert Start and End Dates',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
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
