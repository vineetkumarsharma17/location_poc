import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'dart:io';

class LocationController extends GetxController {
  var isLocationServiceEnabled = false.obs;
  var isTrackingActive = false.obs;
  var currentLocation = Rxn<Position>();
  var locationHistory = <Map<String, dynamic>>[].obs;
  var permissionStatus = ''.obs;
  var backgroundLocationPermission = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLocationHistory();
    checkLocationService();
    checkBackgroundService();
  }

  Future<void> checkBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    isTrackingActive.value = isRunning;
  }

  Future<void> checkLocationService() async {
    isLocationServiceEnabled.value =
        await Geolocator.isLocationServiceEnabled();

    LocationPermission permission = await Geolocator.checkPermission();
    permissionStatus.value = permission.toString();

    // Check background location permission specifically
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 29) {
        // Android 10+
        var bgLocationStatus = await Permission.locationAlways.status;
        backgroundLocationPermission.value = bgLocationStatus.toString();
      }
    }
  }

  Future<bool> requestAllPermissions() async {
    try {
      // Step 1: Request basic location permissions
      LocationPermission permission = await Geolocator.requestPermission();
      print(permission);

      if (permission == LocationPermission.denied) {
        Get.snackbar('Permission Denied', 'Location permission is required');
        return false;
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        Get.snackbar('Permission Denied Forever',
            'Please enable location permission from settings');
        await Geolocator.openAppSettings();
        return false;
      }

      // Step 2: Request notification permission (required for background service)
      await Permission.notification.request();

      // Step 3: Request background location permission for Android 10+
      if (Platform.isAndroid) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt >= 29) {
          // Android 10+
          // First ensure we have foreground location
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            // Show explanation dialog before requesting background permission
            bool userConsents = await _showBackgroundLocationDialog();
            if (!userConsents) return false;

            // Request background location permission
            var bgLocationStatus = await Permission.locationAlways.request();
            print("Background location permission status: $bgLocationStatus");
            backgroundLocationPermission.value = bgLocationStatus.toString();

            if (bgLocationStatus.isDenied ||
                bgLocationStatus.isPermanentlyDenied) {
              Get.snackbar(
                'Background Location Required',
                'Please select "Allow all the time" in location settings for background tracking',
                duration: Duration(seconds: 5),
                mainButton: TextButton(
                  onPressed: () => openAppSettings(),
                  child: Text('Open Settings',
                      style: TextStyle(color: Colors.white)),
                ),
              );
              return false;
            }
          }
        }
      }

      // Step 4: Request battery optimization exemption (Android)
      if (Platform.isAndroid) {
        await _requestBatteryOptimization();
      }

      permissionStatus.value = permission.toString();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      Get.snackbar('Error', 'Failed to request permissions: $e');
      return false;
    }
  }

  Future<bool> _showBackgroundLocationDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Text('Background Location Access'),
            content: Text(
                'This app needs "Always Allow" location permission to track your location even when the app is closed.\n\n'
                'In the next screen, please select "Allow all the time" for location access.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('Continue'),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      await Permission.systemAlertWindow.request();
      await Permission.ignoreBatteryOptimizations.request();

      print(
          "Battery optimization permission status: ${await Permission.ignoreBatteryOptimizations.status}");
      print(
          "System alert window permission status: ${await Permission.systemAlertWindow.status}");
    } catch (e) {
      print('Battery optimization request failed: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      if (!await requestAllPermissions()) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation.value = position;
      print("Current location: ${position.latitude}, ${position.longitude}");
      await saveLocationToHistory(position, 'manual');
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
    }
  }

  Future<void> startLocationTracking() async {
    try {
      if (!await requestAllPermissions()) {
        Get.snackbar('Error', 'Required permissions not granted');
        return;
      }

      final service = FlutterBackgroundService();

      bool isRunning = await service.isRunning();
      if (isRunning) {
        Get.snackbar('Already Running', 'Location tracking is already active');
        return;
      }

      // Start the background service
      await service.startService();

      // Configure the service
      service.invoke("setAsForeground");
      service.invoke("startLocationTracking");

      isTrackingActive.value = true;

      Get.snackbar(
        'Tracking Started',
        'Location will be captured every 10 minutes in the background.\n\nNote: Keep the app in "Don\'t optimize" battery settings.',
        duration: Duration(seconds: 8),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to start tracking: $e');
    }
  }

  Future<void> stopLocationTracking() async {
    final service = FlutterBackgroundService();
    service.invoke("stopLocationTracking");
    service.invoke("stop");

    isTrackingActive.value = false;
    Get.snackbar(
        'Tracking Stopped', 'Background location tracking has been disabled');
  }

  Future<void> saveLocationToHistory(Position position, String source) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> locationData = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'speed': position.speed,
      'heading': position.heading,
      'altitude': position.altitude,
      'source': source,
    };

    locationHistory.insert(0, locationData);

    // Keep only last 100 locations
    if (locationHistory.length > 100) {
      locationHistory.removeRange(100, locationHistory.length);
    }

    String jsonString = jsonEncode(locationHistory.toList());
    await prefs.setString('location_history', jsonString);
  }

  Future<void> loadLocationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('location_history');

    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      locationHistory.value = jsonList.cast<Map<String, dynamic>>();
    }
  }

  Future<void> clearLocationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('location_history');
    locationHistory.clear();
    Get.snackbar('Cleared', 'Location history has been cleared');
  }

  Future<void> openBatterySettings() async {
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> refreshLocationHistory() async {
    await loadLocationHistory();
  }
}
