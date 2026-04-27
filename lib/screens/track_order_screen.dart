// lib/screens/track_order_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_tracking_service.dart';

class TrackOrderScreen extends StatefulWidget {
  // Optionally accept pickup/destination coords from previous screen:
  final LatLng? pickup;
  final LatLng? destination;
  final String orderId;

  const TrackOrderScreen({
    super.key,
    this.pickup,
    this.destination,
    this.orderId = 'ORDER123',
  });

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

enum OrderStep {
  accepted,
  riderToPickup,
  packagePicked,
  riderToDestination,
  delivered,
}

class _TrackOrderScreenState extends State<TrackOrderScreen>
    with TickerProviderStateMixin {
  // Default mock coords (Lagos example) — replace with real place details if available.
  final LatLng _defaultPickup = const LatLng(6.5244, 3.3792); // Lagos center
  final LatLng _defaultDestination =
      const LatLng(6.4453, 3.3915); // another point in Lagos

  late MapController _mapController;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  // Rider state (real-time from Firestore)
  LatLng? _riderPosition;
  StreamSubscription<QuerySnapshot>? _locationSubscription;

  // Timeline state
  OrderStep _currentStep = OrderStep.accepted;

  // Rider details (mock - would come from delivery data in real app)
  final String _riderName = 'John Doe';
  final String _riderPhone = '+2348012345678';
  final String _vehicle = 'Motorbike • KAV 2019';
  final double _riderRating = 4.9;

  // ETA & distance (estimated based on rider position)
  int _minutesRemaining = 8;
  double _distanceRemainingKm = 3.2;

  late AnimationController _cardAnimController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _cardAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _setupInitialMarkers();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _cardAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _setupInitialMarkers() {
    final pickup = widget.pickup ?? _defaultPickup;
    final dest = widget.destination ?? _defaultDestination;

    _markers.clear();
    _markers.add(Marker(
      point: pickup,
      child: const Icon(Icons.location_on, color: Colors.green, size: 40),
    ));
    _markers.add(Marker(
      point: dest,
      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
    ));

    // Rider marker will be added when location data is received
    if (_riderPosition != null) {
      _markers.add(Marker(
        point: _riderPosition!,
        child: const Icon(Icons.directions_bike, color: Colors.blue, size: 40),
      ));
    }

    // Simple polyline between pickup and destination
    _polylines.clear();
    _polylines.add(Polyline(
      points: [pickup, dest],
      color: Colors.deepPurple,
      strokeWidth: 3,
    ));
  }

  void _startLocationTracking() {
    // Listen to real-time location updates from Firestore
    _locationSubscription = LocationTrackingService()
        .getLocationUpdates(widget.orderId)
        .listen((snapshot) {
      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final latestLocation =
            snapshot.docs.first.data() as Map<String, dynamic>?;
        if (latestLocation != null) {
          final lat = latestLocation['latitude'] as double?;
          final lng = latestLocation['longitude'] as double?;

          if (lat != null && lng != null) {
            final newPosition = LatLng(lat, lng);
            _updateRiderPosition(newPosition);
          }
        }
      }
    });

    // Also try to get the latest location immediately
    _loadLatestLocation();
  }

  Future<void> _loadLatestLocation() async {
    final locationData =
        await LocationTrackingService().getLatestLocation(widget.orderId);
    if (locationData != null && mounted) {
      final lat = locationData['latitude'] as double?;
      final lng = locationData['longitude'] as double?;
      if (lat != null && lng != null) {
        final position = LatLng(lat, lng);
        _updateRiderPosition(position);
      }
    }
  }

  void _updateRiderPosition(LatLng newPosition) {
    // Remove old rider marker
    _markers.removeWhere((marker) =>
        marker.child is Icon &&
        (marker.child as Icon).icon == Icons.directions_bike);

    // Add new rider marker
    _markers.add(Marker(
      point: newPosition,
      child: const Icon(Icons.directions_bike, color: Colors.blue, size: 40),
    ));

    _riderPosition = newPosition;

    // Update ETA and distance based on current position
    _updateETA();

    // Animate camera to rider position
    _mapController.move(newPosition, _mapController.camera.zoom);

    setState(() {});
  }

  void _updateETA() {
    if (_riderPosition == null) return;

    final dest = widget.destination ?? _defaultDestination;
    _distanceRemainingKm = _estimateDistanceKm(_riderPosition!, dest);

    // Estimate time based on distance (assuming average speed of 30 km/h)
    const averageSpeedKmh = 30.0;
    final hoursRemaining = _distanceRemainingKm / averageSpeedKmh;
    _minutesRemaining = max(1, (hoursRemaining * 60).round());
  }

  // Utility to make an interpolated route between two points
  List<LatLng> _interpolateRoute(LatLng a, LatLng b, int steps) {
    final List<LatLng> pts = [];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = _lerp(a.latitude, b.latitude, t) + _jitter(i, steps);
      final lng = _lerp(a.longitude, b.longitude, t) + _jitter(i + 13, steps);
      pts.add(LatLng(lat, lng));
    }
    return pts;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
  double _jitter(int i, int steps) {
    // small predictable jitter so route doesn't look perfectly straight
    final r = (i % 3) - 1; // -1,0,1
    return r * 0.00012; // tiny offset
  }

  double _estimateDistanceKm(LatLng a, LatLng b) {
    const earth = 6371.0; // km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final hav = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
    return double.parse((earth * c).toStringAsFixed(1));
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  // -----------------------
  // UI Building
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final pickup = widget.pickup ?? _defaultPickup;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking — ${widget.orderId}'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: pickup,
              initialZoom: 13.5,
              onMapReady: () {
                // fit bounds to show entire route
                Future.delayed(const Duration(milliseconds: 500), () {
                  _fitMapToRoute();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: _markers),
              PolylineLayer(polylines: _polylines),
            ],
          ),

          // Top floating card: status & ETA
          Positioned(
            top: 16,
            left: 12,
            right: 12,
            child: _floatingStatusCard(),
          ),

          // Vertical timeline on the right
          Positioned(
            top: 110,
            right: 8,
            child: _timelineColumn(),
          ),

          // Bottom rider card
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _bottomRiderCard(),
          ),
        ],
      ),
    );
  }

  Future<void> _fitMapToRoute() async {
    final pickup = widget.pickup ?? _defaultPickup;
    final dest = widget.destination ?? _defaultDestination;
    final riderPos = _riderPosition;

    List<LatLng> points = [pickup, dest];
    if (riderPos != null) {
      points.add(riderPos);
    }

    LatLngBounds bounds = _boundsFromLatLngList(points);
    try {
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
    } catch (_) {
      // can't animate immediately sometimes; ignore
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> pts) {
    if (pts.isEmpty) return LatLngBounds(_defaultPickup, _defaultDestination);

    var south = pts.first.latitude;
    var north = pts.first.latitude;
    var west = pts.first.longitude;
    var east = pts.first.longitude;
    for (final p in pts) {
      south = min(south, p.latitude);
      north = max(north, p.latitude);
      west = min(west, p.longitude);
      east = max(east, p.longitude);
    }
    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  Widget _floatingStatusCard() {
    final statusText = _statusTextForStep(_currentStep);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                        'ETA: $_minutesRemaining min • ${_distanceRemainingKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ]),
            ),
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(_riderRatingShort(),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _riderRatingShort() => _riderRating.toStringAsFixed(1);

  String _statusTextForStep(OrderStep s) {
    switch (s) {
      case OrderStep.accepted:
        return 'Order accepted';
      case OrderStep.riderToPickup:
        return 'Rider is on the way to pickup';
      case OrderStep.packagePicked:
        return 'Package picked';
      case OrderStep.riderToDestination:
        return 'Rider heading to destination';
      case OrderStep.delivered:
        return 'Delivered';
    }
  }

  Widget _timelineColumn() {
    // vertical timeline showing 5 steps
    final steps = [
      'Order accepted',
      'Rider to pickup',
      'Package picked',
      'Rider to destination',
      'Delivered',
    ];
    final stepEnums = OrderStep.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(steps.length, (i) {
        final step = stepEnums[i];
        final done = step.index < _currentStep.index ||
            step == _currentStep && _currentStep == OrderStep.delivered;
        final active =
            step == _currentStep && _currentStep != OrderStep.delivered;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // dot & line
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: done
                          ? Colors.green
                          : (active ? Colors.deepPurple : Colors.white),
                      border: Border.all(
                          color: done || active
                              ? Colors.transparent
                              : Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  if (i != steps.length - 1)
                    Container(
                      width: 2,
                      height: 36,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                ],
              ),

              const SizedBox(width: 8),

              // text card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.deepPurple.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: Colors.deepPurple
                                  .withAlpha((0.06 * 255).round()),
                              blurRadius: 6)
                        ]
                      : null,
                ),
                child: Text(
                  steps[i],
                  style: TextStyle(
                    color: done
                        ? Colors.green.shade700
                        : (active ? Colors.deepPurple : Colors.black87),
                    fontWeight:
                        active || done ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _bottomRiderCard() {
    final rName = _riderName;
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // top row: rider + basic info + ETA
            Row(
              children: [
                CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(rName.substring(0, 1))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_vehicle,
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 13)),
                      ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$_minutesRemaining min',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_distanceRemainingKm.toStringAsFixed(1)} km',
                      style: const TextStyle(color: Colors.black54)),
                ]),
              ],
            ),
            const SizedBox(height: 8),

            // action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _callNumber(_riderPhone),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _openChat(),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _cancelOrder,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // small progress / instructions
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Expanded(
                    child:
                        Text('Rider is on the move — stay at pickup location')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone')));
      }
    }
  }

  void _openChat() {
    // Hook into your app's chat flow
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open chat (not implemented)')));
    }
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Delivery?'),
        content: const Text('Are you sure you want to cancel this delivery?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Stop location tracking
              LocationTrackingService().stopTracking();
              Navigator.pop(context); // go back
            },
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }
}
