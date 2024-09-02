import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GooglMapPage extends StatefulWidget {
  const GooglMapPage({super.key});

  @override
  State<GooglMapPage> createState() => _GooglMapPageState();
}

class _GooglMapPageState extends State<GooglMapPage> {
  static const colombo = LatLng(6.927079, 79.861244);
  static const gallface = LatLng(6.9286, 79.8451);

  bool isListening = false;
  LatLng? currentPosition;
  Map<PolylineId, Polyline> polylines = {};
  final locationContoller = Location();
  StreamSubscription<LocationData>? locationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async => await initMap(),
    );
  }

  Future<void> initMap() async {
    await fetchLocationUpdates();
    final cordinate = await fetchPolyLinepoints();
    genaratePolyLineFromPoints(cordinate);
  }

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationContoller.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationContoller.requestService();
    } else {
      return;
    }

    permissionGranted = await locationContoller.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationContoller.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    if (!isListening) {
      locationSubscription =
          locationContoller.onLocationChanged.listen((currentLocation) {
        if (currentLocation.latitude != null &&
            currentLocation.longitude != null) {
          setState(() {
            currentPosition =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
          });
        }
        debugPrint(currentPosition!.toString());
      });
      isListening = true;
    }
  }

  Future<List<LatLng>> fetchPolyLinepoints() async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
        "your_api_key",
        PointLatLng(colombo.latitude, colombo.longitude),
        PointLatLng(gallface.latitude, gallface.longitude));

    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> genaratePolyLineFromPoints(
      List<LatLng> polylineCordinates) async {
    const id = PolylineId("polyline");

    final polyline = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCordinates,
        width: 5);

    setState(() {
      polylines[id] = polyline;
    });
  }

  @override
  void dispose() {
    locationSubscription?.cancel(); // Cancel the subscription if necessary
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: colombo,
                zoom: 13,
              ),
              markers: {
                Marker(
                    markerId: const MarkerId('currentLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: currentPosition!),
                const Marker(
                    markerId: MarkerId('sourceLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: colombo),
                const Marker(
                    markerId: MarkerId('destionationLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: gallface),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }
}
