// // screens/home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:location_poc/location/controller.dart';
// import 'dart:io';

// class HomeScreen extends StatelessWidget {
//   final LocationController locationController = Get.find();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Location Tracker POC'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: () {
//               locationController.checkLocationService();
//               locationController.checkBackgroundService();
//               locationController.refreshLocationHistory();
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status Cards
//             _buildStatusCard(),

//             SizedBox(height: 16),

//             // Permission Status
//             _buildPermissionCard(),

//             SizedBox(height: 16),

//             // Action Buttons
//             _buildActionButtons(),

//             SizedBox(height: 16),

//             // Current Location Display
//             _buildCurrentLocationCard(),

//             SizedBox(height: 16),

//             // Location History
//             _buildLocationHistorySection(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Card(
//       color: Colors.blue.shade50,
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.info_outline, color: Colors.blue),
//                 SizedBox(width: 8),
//                 Text(
//                   'Tracking Status',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue.shade800,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//             Obx(() => Row(
//                   children: [
//                     Container(
//                       width: 12,
//                       height: 12,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: locationController.isTrackingActive.value
//                             ? Colors.green
//                             : Colors.red,
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Text(
//                       locationController.isTrackingActive.value
//                           ? 'Background Tracking Active'
//                           : 'Background Tracking Inactive',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 )),
//             SizedBox(height: 8),
//             Text(
//               'Captures location every 10 minutes even when app is closed',
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPermissionCard() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Permissions',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8),
//             Obx(() => Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildPermissionRow(
//                       'Location Service',
//                       locationController.isLocationServiceEnabled.value,
//                     ),
//                     _buildPermissionRow(
//                       'Basic Location',
//                       locationController.permissionStatus.value
//                               .contains('whileInUse') ||
//                           locationController.permissionStatus.value
//                               .contains('always'),
//                     ),
//                     if (Platform.isAndroid &&
//                         locationController
//                             .backgroundLocationPermission.value.isNotEmpty)
//                       _buildPermissionRow(
//                         'Background Location',
//                         locationController.backgroundLocationPermission.value
//                             .contains('granted'),
//                       ),
//                   ],
//                 )),
//             SizedBox(height: 8),
//             TextButton.icon(
//               onPressed: () => locationController.openBatterySettings(),
//               icon: Icon(Icons.battery_saver, size: 16),
//               label: Text('Battery Settings', style: TextStyle(fontSize: 12)),
//               style: TextButton.styleFrom(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPermissionRow(String title, bool granted) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Icon(
//             granted ? Icons.check_circle : Icons.cancel,
//             color: granted ? Colors.green : Colors.red,
//             size: 16,
//           ),
//           SizedBox(width: 8),
//           Text(
//             title,
//             style: TextStyle(fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () => locationController.getCurrentLocation(),
//                 icon: Icon(Icons.my_location),
//                 label: Text('Get Current Location'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: Obx(() => ElevatedButton.icon(
//                     onPressed: locationController.isTrackingActive.value
//                         ? () => locationController.stopLocationTracking()
//                         : () => locationController.startLocationTracking(),
//                     icon: Icon(locationController.isTrackingActive.value
//                         ? Icons.stop
//                         : Icons.play_arrow),
//                     label: Text(locationController.isTrackingActive.value
//                         ? 'Stop Background Tracking'
//                         : 'Start Background Tracking'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: locationController.isTrackingActive.value
//                           ? Colors.red
//                           : Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                   )),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildCurrentLocationCard() {
//     return Obx(() {
//       if (locationController.currentLocation.value != null) {
//         var loc = locationController.currentLocation.value!;
//         return Card(
//           color: Colors.green.shade50,
//           child: Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.location_on, color: Colors.green),
//                     SizedBox(width: 8),
//                     Text(
//                       'Current Location',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green.shade800,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Text('Latitude: ${loc.latitude.toStringAsFixed(6)}'),
//                 Text('Longitude: ${loc.longitude.toStringAsFixed(6)}'),
//                 Text('Accuracy: ${loc.accuracy.toStringAsFixed(2)}m'),
//                 Text('Speed: ${loc.speed.toStringAsFixed(2)} m/s'),
//               ],
//             ),
//           ),
//         );
//       }
//       return SizedBox();
//     });
//   }

//   Widget _buildLocationHistorySection() {
//     return Expanded(
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Location History',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Row(
//                 children: [
//                   IconButton(
//                     onPressed: () =>
//                         locationController.refreshLocationHistory(),
//                     icon: Icon(Icons.refresh, size: 20),
//                   ),
//                   TextButton(
//                     onPressed: () => locationController.clearLocationHistory(),
//                     child: Text('Clear All'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           Expanded(
//             child: Obx(() => locationController.locationHistory.isEmpty
//                 ? Center(
//                     child: Text(
//                       'No location history yet.\nStart tracking or get current location.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   )
//                 : ListView.builder(
//                     itemCount: locationController.locationHistory.length,
//                     itemBuilder: (context, index) {
//                       var location = locationController.locationHistory[index];
//                       var timestamp = DateTime.parse(location['timestamp']);
//                       var source = location['source'] ?? 'unknown';

//                       return Card(
//                         margin: EdgeInsets.symmetric(vertical: 4),
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: source == 'background_service'
//                                 ? Colors.orange.shade100
//                                 : Colors.blue.shade100,
//                             child: Icon(
//                               source == 'background_service'
//                                   ? Icons.schedule
//                                   : Icons.location_on,
//                               color: source == 'background_service'
//                                   ? Colors.orange.shade800
//                                   : Colors.blue.shade800,
//                               size: 20,
//                             ),
//                           ),
//                           title: Text(
//                             '${location['latitude'].toStringAsFixed(5)}, ${location['longitude'].toStringAsFixed(5)}',
//                             style: TextStyle(
//                                 fontSize: 14, fontWeight: FontWeight.w500),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
//                                 style: TextStyle(fontSize: 12),
//                               ),
//                               Text(
//                                 'Accuracy: ${location['accuracy'].toStringAsFixed(1)}m • Speed: ${(location['speed'] ?? 0).toStringAsFixed(1)}m/s',
//                                 style: TextStyle(
//                                     fontSize: 11, color: Colors.grey[600]),
//                               ),
//                             ],
//                           ),
//                           trailing: Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: source == 'background_service'
//                                   ? Colors.orange.shade100
//                                   : Colors.blue.shade100,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               source == 'background_service' ? 'BG' : 'Manual',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.bold,
//                                 color: source == 'background_service'
//                                     ? Colors.orange.shade800
//                                     : Colors.blue.shade800,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   )),
//           ),
//         ],
//       ),
//     );
//   }
// }
