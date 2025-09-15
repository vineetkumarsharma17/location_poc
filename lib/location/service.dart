// // services/background_location_service.dart
// import 'dart:async';
// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'location_tracker_channel',
//     'Location Tracker',
//     description: 'This channel is used for location tracking notifications.',
//     importance: Importance.low,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   if (Platform.isAndroid) {
//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }

//   await service.configure(
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       notificationChannelId: 'location_tracker_channel',
//       initialNotificationTitle: 'Location Tracker',
//       initialNotificationContent: 'Tracking your location in background',
//       foregroundServiceNotificationId: 888,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   Timer? locationTimer;
//   bool isTracking = false;

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   Future<void> saveLocationToPrefs(Position position) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();

//       Map<String, dynamic> locationData = {
//         'latitude': position.latitude,
//         'longitude': position.longitude,
//         'accuracy': position.accuracy,
//         'timestamp': DateTime.now().toIso8601String(),
//         'speed': position.speed,
//         'heading': position.heading,
//         'altitude': position.altitude,
//         'source': 'background_service',
//       };

//       // Get existing history
//       String? existingData = prefs.getString('location_history');
//       List<Map<String, dynamic>> history = [];

//       if (existingData != null) {
//         List<dynamic> jsonList = jsonDecode(existingData);
//         history = jsonList.cast<Map<String, dynamic>>();
//       }

//       // Add new location at the beginning
//       history.insert(0, locationData);

//       // Keep only last 100 locations
//       if (history.length > 100) {
//         history = history.sublist(0, 100);
//       }

//       // Save back to SharedPreferences
//       String jsonString = jsonEncode(history);
//       await prefs.setString('location_history', jsonString);

//       print('Location saved to history: ${history.length} total locations');
//     } catch (e) {
//       print('Error saving location to preferences: $e');
//     }
//   }

//   service.on('stopService').listen((event) {
//     locationTimer?.cancel();
//     service.stopSelf();
//   });

//   Future<void> captureLocation() async {
//     try {
//       print('Attempting to capture location...');

//       // Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         print('Location services are disabled');
//         return;
//       }

//       // Check permissions
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         print('Location permissions are denied');
//         return;
//       }

//       // Get current location with timeout
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.medium,
//         timeLimit: Duration(seconds: 60),
//       ).timeout(Duration(seconds: 60));

//       print('Location captured: ${position.latitude}, ${position.longitude}');

//       // Save to SharedPreferences
//       await saveLocationToPrefs(position);

//       // Update notification
//       if (Platform.isAndroid) {
//         flutterLocalNotificationsPlugin.show(
//           888,
//           'Location Tracker',
//           'Last update: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
//           const NotificationDetails(
//             android: AndroidNotificationDetails(
//               'location_tracker_channel',
//               'Location Tracker',
//               icon: 'ic_bg_service_small',
//               ongoing: true,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error capturing location: $e');
//     }
//   }

//   service.on('startLocationTracking').listen((event) async {
//     if (isTracking) return;

//     isTracking = true;
//     print('Starting location tracking service');

//     // Capture location immediately
//     await captureLocation();

//     // Set up timer for every 10 minutes (600 seconds)
//     locationTimer = Timer.periodic(Duration(minutes: 10), (timer) async {
//       await captureLocation();
//     });
//   });

//   service.on('stopLocationTracking').listen((event) {
//     isTracking = false;
//     locationTimer?.cancel();
//     print('Stopping location tracking service');
//   });
// }
