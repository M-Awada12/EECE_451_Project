import 'dart:async';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'Widgets/Status.dart';
import 'Widgets/Statistics.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Network Analyzer',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 191, 219, 255)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebSocketChannel channel;
  static const platform = const MethodChannel('telephony_channel');
  var selectedIndex = 0;
  String error = '';
  String? MACAddress = '';
  String? IPAddress = '';

  Future<void> _getTelephonyInfo() async {
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('getTelephonyInfo');
      setState(() {
        MACAddress = result['macAddress'];
        IPAddress = result['ipAddress'];
        error = '';
      });

      channel.sink.add('$MACAddress,$IPAddress');
    } on PlatformException catch (e) {
      setState(() {
        error = "Failed to get telephony info: '${e.message}'.";
      });
    }
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

  @override
  void initState() {
    super.initState();
    _initializeWebSocketConnection();
  }

  Future<void> _initializeWebSocketConnection() async {
    while (true) {
      try {
        channel = IOWebSocketChannel.connect('ws://four51-server.onrender.com/ws');
        await _requestLocationPermission();
        break;
      } catch (e) {
        print("WebSocket connection failed: $e");
        await Future.delayed(Duration(minutes: 1)); // Wait for 1 minute before retrying
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = Status();
        break;
      case 1:
        page = Statistics();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.router),
                    label: Text('View Status'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.signal_cellular_alt),
                    label: Text('Max Charging Current'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}
