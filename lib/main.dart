import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location_poc/location/controller.dart';
import 'package:location_poc/location/home.dart';
import 'package:location_poc/location/service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await initializeService();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Location Tracker POC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      getPages: [
        GetPage(name: '/', page: () => HomeScreen()),
      ],
      initialRoute: '/',
      initialBinding: BindingsBuilder.put(() => LocationController()),
    );
  }
}
