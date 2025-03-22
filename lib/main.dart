import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LocationScreen());
  }
}

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _currentPosition;
  String _locationText = 'Checking location permissions...';
  Position? _lastSentPosition; // Store the last sent position

  @override
  void initState() {
    super.initState();
    _checkAndStartLocationUpdates();
  }

  Future<void> _checkAndStartLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationText = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationText = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationText =
            'Location permissions are permanently denied, we cannot request permissions.';
      });
      return;
    }

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _getLocation();
    Timer.periodic(Duration(seconds: 5), (timer) {
      _getLocation();
    });
  }

  Future<void> _getLocation() async {
  try {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, // Use high accuracy
      distanceFilter: 5, // Optional: filter out small movements
    );

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    if (_lastSentPosition == null || _hasMoved(position, _lastSentPosition!)) {
      setState(() {
        _currentPosition = position;
        _locationText =
            'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
        _sendLocation(position.latitude, position.longitude);
        _lastSentPosition = position; // Update the last sent position
      });
    } else {
      print("location did not change.");
    }
  } catch (e) {
    setState(() {
      _locationText = 'Error getting location: $e';
    });
  }
}

  bool _hasMoved(Position current, Position last) {
    // You can adjust the distance threshold as needed
    double distance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      last.latitude,
      last.longitude,
    );
    return distance > 5; // Check if moved more than 5 meters
  }

  Future<void> _sendLocation(double latitude, double longitude) async {
    try {
      await http.post(
        Uri.parse('http://<ip-address>:5000/location'), // Place your Target ip address here. Also make sure that both devices are on same network
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );
      print('Location sent to Raspberry Pi');
    } catch (error) {
      print('Error sending location: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Sharing App')),
      body: Center(child: Text(_locationText)),
      floatingActionButton: FloatingActionButton(
        onPressed: _getLocation,
        child: Icon(Icons.refresh),
      ),
    );
  }
}