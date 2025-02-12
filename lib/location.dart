import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class MapLocation extends StatefulWidget {
  const MapLocation({Key? key}) : super(key: key);

  @override
  State<MapLocation> createState() => _MapLocationState();
}

class _MapLocationState extends State<MapLocation> {
  final Completer<GoogleMapController> _controller = Completer();
  final DatabaseService _databaseService = DatabaseService();

  bool _loading = true;
  LatLng _currentLocation = const LatLng(6.148207, 80.169941);
  String deviceID = "Unknown";
  int battery = 0;
  double weight = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully");

      _databaseService.fetchBagDetails((location, details) {
        setState(() {
          _currentLocation = location;
          deviceID = details['deviceID'] ?? "Unknown";
          battery = details['battery'] ?? 0;
          weight = details['weight'] ?? 0.0;
          _loading = false;
        });
        _updateMapPosition();
        print(
            "Data fetched successfully: DeviceID: $deviceID, Battery: $battery%, Latitude: ${_currentLocation.latitude}, Longitude: ${_currentLocation.longitude}");
      });
    } catch (e) {
      print("Firebase initialization failed: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateMapPosition() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(_currentLocation));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bag Location Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.hybrid, // Hybrid map type
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 15.0,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: _currentLocation,
                      infoWindow: InfoWindow(
                        title: "Bag Location",
                        snippet:
                            "Device: $deviceID | Battery: $battery% | Weight: ${weight}kg",
                      ),
                    ),
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  zoomControlsEnabled: false,
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Device ID: $deviceID",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Battery: $battery%"),
                        Text("Weight: ${weight}kg"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class DatabaseService {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref(); // No nested 'bags'

  void fetchBagDetails(Function(LatLng, Map<String, dynamic>) onUpdate) {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print("Raw Data from Firebase: $data");

      if (data != null && data is Map<dynamic, dynamic>) {
        // Access the root-level keys
        var value = data;

        if (value is Map<dynamic, dynamic>) {
          double lat =
              double.tryParse(value['latitude']?.toString() ?? '') ?? 6.148182;
          double lng = double.tryParse(value['longitude']?.toString() ?? '') ??
              80.170491;

          Map<String, dynamic> details = {
            'deviceID': value['deviceID']?.toString() ?? 'Unknown',
            'battery': int.tryParse(value['battery']?.toString() ?? '0') ?? 0,
            'weight':
                double.tryParse(value['weight']?.toString() ?? '0.0') ?? 0.0,
          };

          onUpdate(LatLng(lat, lng), details);
        }
      } else {
        print("Data format is incorrect or data is not available.");
      }
    });
  }
}
