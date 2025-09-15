import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocationTrackerPage(),
    );
  }
}

class LocationTrackerPage extends StatefulWidget {
  @override
  _LocationTrackerPageState createState() => _LocationTrackerPageState();
}

class _LocationTrackerPageState extends State<LocationTrackerPage> {
  static const platform = MethodChannel('com.example.locationtracker/location');
  bool isServiceRunning = false;
  String lastLocation = "No location yet";

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _setupLocationListener();
  }

  void _setupLocationListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onLocationUpdate') {
        setState(() {
          lastLocation = call.arguments.toString();
        });
      }
    });
  }

  Future<void> _checkServiceStatus() async {
    try {
      final bool result = await platform.invokeMethod('isServiceRunning');
      setState(() {
        isServiceRunning = result;
      });
    } catch (e) {
      print('Error checking service status: $e');
    }
  }

  Future<void> _startLocationService() async {
    try {
      await platform.invokeMethod('startLocationService');
      setState(() {
        isServiceRunning = true;
      });
    } catch (e) {
      print('Error starting location service: $e');
      _showError('Failed to start location service: $e');
    }
  }

  Future<void> _stopLocationService() async {
    try {
      await platform.invokeMethod('stopLocationService');
      setState(() {
        isServiceRunning = false;
      });
    } catch (e) {
      print('Error stopping location service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await platform.invokeMethod('requestPermissions');
    } catch (e) {
      print('Error requesting permissions: $e');
      _showError('Failed to request permissions: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tracker'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Service Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      isServiceRunning ? 'Running' : 'Stopped',
                      style: TextStyle(
                        color: isServiceRunning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Last Location',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      lastLocation,
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: Text('Request Permissions'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isServiceRunning ? null : _startLocationService,
              child: Text('Start Location Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isServiceRunning ? _stopLocationService : null,
              child: Text('Stop Location Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
