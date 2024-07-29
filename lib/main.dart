// ignore_for_file: unused_element, unused_local_variable, avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const StreetMapProject());
}

class StreetMapProject extends StatefulWidget {
  const StreetMapProject({super.key});

  @override
  State<StreetMapProject> createState() => _StreetMapProjectState();
}

class _StreetMapProjectState extends State<StreetMapProject> {
  LocationData? currentLocation;
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];
  List<Marker> markers = [];
  final String apiKey =
      "5b3ce3597851110001cf6248cd7cccd3e9b14ff399db4237b84c25ff";
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Street Maps",
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Street Map Project'),
        ),
        body: currentLocation == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              )
            : FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!),
                  initialZoom: 15,
                  onTap: (tapPosition, point) {
                    getDestinationMarker(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: markers),
                  PolylineLayer(polylines: [
                    Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 4),
                  ]),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            mapController.move(
                LatLng(
                  currentLocation!.latitude!,
                  currentLocation!.longitude!,
                ),
                15);
          },
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }

  void _getCurrentLocation() async {
    var location = Location();
    try {
      var userLocation = await location.getLocation();
      setState(() {
        currentLocation = userLocation;
        markers.add(Marker(
            width: 40,
            height: 40,
            point: LatLng(userLocation.latitude!, userLocation.longitude!),
            child: const Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 40,
            )));
      });
    } on Exception catch (e) {
      currentLocation = null;
      throw e.toString();
    }
    location.onLocationChanged.listen((LocationData newLocation) {
      setState() {
        currentLocation = newLocation;
      }
    });
  }

  Future<void> _getRoute(LatLng destination) async {
    if (currentLocation == null) return;
    final start =
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
    final response = await http.get(
      Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${destination.longitude},${destination.latitude}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> coords =
          data['features'][0]['geometry']['coordinates'];
      setState(() {
        routePoints =
            coords.map((coord) => LatLng(coord[1], coord[0])).toList();
        markers.add(Marker(
          width: 40,
          height: 40,
          point: destination,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ));
      });
    } else {
      print('Failed to get route');
    }
  }

  void getDestinationMarker(LatLng point) {
    setState(() {
      // markers.clear();
      markers.add(Marker(
        width: 40,
        height: 40,
        point: point,
        child: const Icon(
          Icons.location_on,
          color: Colors.green,
          size: 40,
        ),
      ));
    });
    _getRoute(point);
  }
}
