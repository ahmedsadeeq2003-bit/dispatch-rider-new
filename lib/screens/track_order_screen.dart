// lib/screens/track_order_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/location_tracking_service.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

/// The active-delivery experience — the flagship screen of the app. Real
/// delivery state drives everything here (no mock rider, no fake timeline):
/// `deliveries.status` (accepted/picked_up/in_transit/completed) IS the
/// progression, and one primary action is shown at a time so a rider moving
/// mid-shift always knows exactly what to do next.
class TrackOrderScreen extends StatefulWidget {
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

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final LatLng _fallbackCenter = const LatLng(9.0765, 7.3986); // Abuja fallback

  late MapController _mapController;
  StreamSubscription<List<Map<String, dynamic>>>? _locationSubscription;
  LatLng? _riderPosition;

  Map<String, dynamic>? _delivery;
  StreamSubscription<Map<String, dynamic>?>? _deliverySubscription;
  Map<String, dynamic>? _counterpartProfile; // the "other side" of this job
  bool _actionInFlight = false;

  double? _distanceRemainingKm;

  String? get _myUid => Supabase.instance.client.auth.currentUser?.id;
  bool get _isRider => _delivery != null && _delivery!['rider_id'] == _myUid;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _subscribeToDelivery();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _deliverySubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _subscribeToDelivery() {
    _deliverySubscription = DeliveryService.getDelivery(widget.orderId).listen((data) async {
      if (!mounted || data == null) return;
      final counterpartId = _myUid == data['rider_id'] ? data['client_id'] : data['rider_id'];
      if (_counterpartProfile == null || _counterpartProfile!['id'] != counterpartId) {
        _loadCounterpart(counterpartId as String?);
      }
      setState(() => _delivery = data);
      _updateDistance();
    });
  }

  Future<void> _loadCounterpart(String? id) async {
    if (id == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, phone_number, rating')
        .eq('id', id)
        .maybeSingle();
    if (!mounted) return;
    setState(() => _counterpartProfile = profile);
  }

  void _startLocationTracking() {
    _locationSubscription =
        LocationTrackingService().getLocationUpdates(widget.orderId).listen((rows) {
      if (!mounted || rows.isEmpty) return;
      final lat = (rows.first['lat'] as num?)?.toDouble();
      final lng = (rows.first['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        setState(() => _riderPosition = LatLng(lat, lng));
        _updateDistance();
        try {
          _mapController.move(_riderPosition!, _mapController.camera.zoom);
        } catch (_) {}
      }
    });
  }

  LatLng? get _pickup {
    final lat = (_delivery?['pickup_lat'] as num?)?.toDouble() ?? widget.pickup?.latitude;
    final lng = (_delivery?['pickup_lng'] as num?)?.toDouble() ?? widget.pickup?.longitude;
    if (lat == null || lng == null) return widget.pickup;
    return LatLng(lat, lng);
  }

  LatLng? get _dropoff {
    final lat = (_delivery?['dropoff_lat'] as num?)?.toDouble() ?? widget.destination?.latitude;
    final lng = (_delivery?['dropoff_lng'] as num?)?.toDouble() ?? widget.destination?.longitude;
    if (lat == null || lng == null) return widget.destination;
    return LatLng(lat, lng);
  }

  void _updateDistance() {
    final status = _delivery?['status'] as String?;
    final target = status == 'accepted' ? _pickup : _dropoff;
    if (_riderPosition == null || target == null) return;
    _distanceRemainingKm = _estimateDistanceKm(_riderPosition!, target);
  }

  double _estimateDistanceKm(LatLng a, LatLng b) {
    const earth = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final hav = sin(dLat / 2) * sin(dLat / 2) + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
    return double.parse((earth * c).toStringAsFixed(1));
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  // ---------------------------------------------------------------------
  // Rider actions — one primary action per stage.
  // ---------------------------------------------------------------------
  Future<void> _advance(String nextStatus) async {
    setState(() => _actionInFlight = true);
    try {
      await DeliveryService.updateDeliveryStatus(widget.orderId, nextStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  Future<void> _openCompletionSheet() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CompletionSheet(
        destination: _delivery?['dropoff_address'] as String? ?? 'destination',
        price: (_delivery?['price_naira'] as num?)?.toDouble() ?? 0,
      ),
    );
    if (confirmed != true) return;
    await _advance('completed');
    await LocationTrackingService().stopTracking();
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeliveredSuccessDialog(
        price: (_delivery?['price_naira'] as num?)?.toDouble() ?? 0,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _releaseJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release this job?'),
        content: const Text('It will go back to the pending pool for other riders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Release', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DeliveryService.releaseDelivery(widget.orderId);
    await LocationTrackingService().stopTracking();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clientCancel() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this delivery?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason (required)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Delivery', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || reasonController.text.trim().isEmpty) return;
    try {
      await DeliveryService.cancelDelivery(widget.orderId, reasonController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _callNumber(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final status = _delivery?['status'] as String? ?? 'accepted';
    final pickup = _pickup ?? _fallbackCenter;
    final dropoff = _dropoff ?? _fallbackCenter;

    final markers = <Marker>[
      Marker(
        point: pickup,
        child: const Icon(Icons.circle, color: AppColors.accentGreen, size: 18),
      ),
      Marker(
        point: dropoff,
        child: const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 34),
      ),
      if (_riderPosition != null)
        Marker(
          point: _riderPosition!,
          width: 44,
          height: 44,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _riderPosition ?? pickup,
              initialZoom: 13.5,
              onMapReady: () => Future.delayed(
                const Duration(milliseconds: 400),
                () => _fitMapToRoute(pickup, dropoff),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dispatch_rider_new',
              ),
              MarkerLayer(markers: markers),
              PolylineLayer(polylines: [
                Polyline(points: [pickup, dropoff], color: AppColors.primary, strokeWidth: 3),
              ]),
            ],
          ),

          // Back button — floats over the map, no AppBar competing for space.
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: _MapControlButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(child: _StageBanner(status: status)),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: _delivery == null
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : FadeSlideIn(
                    child: _JobSheet(
                      delivery: _delivery!,
                      counterpart: _counterpartProfile,
                      isRider: _isRider,
                      distanceKm: _distanceRemainingKm,
                      actionInFlight: _actionInFlight,
                      onCall: () => _callNumber(_counterpartProfile?['phone_number'] as String?),
                      onPrimaryAction: () {
                        switch (status) {
                          case 'accepted':
                            _advance('picked_up');
                            break;
                          case 'picked_up':
                            _advance('in_transit');
                            break;
                          case 'in_transit':
                            _openCompletionSheet();
                            break;
                        }
                      },
                      onRelease: _isRider && status == 'accepted' ? _releaseJob : null,
                      onClientCancel:
                          !_isRider && status == 'accepted' ? _clientCancel : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _fitMapToRoute(LatLng pickup, LatLng dropoff) async {
    final points = [pickup, dropoff, if (_riderPosition != null) _riderPosition!];
    var south = points.first.latitude, north = points.first.latitude;
    var west = points.first.longitude, east = points.first.longitude;
    for (final p in points) {
      south = min(south, p.latitude);
      north = max(north, p.latitude);
      west = min(west, p.longitude);
      east = max(east, p.longitude);
    }
    try {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds(LatLng(south, west), LatLng(north, east)),
        padding: const EdgeInsets.fromLTRB(60, 140, 60, 320),
      ));
    } catch (_) {}
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mapControlSurface,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _StageBanner extends StatelessWidget {
  final String status;
  const _StageBanner({required this.status});

  static const _labels = {
    'accepted': 'Heading to pickup',
    'picked_up': 'Package collected',
    'in_transit': 'On the way to destination',
    'completed': 'Delivered',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.mapControlSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        _labels[status] ?? status,
        style: AppText.body.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _JobSheet extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final Map<String, dynamic>? counterpart;
  final bool isRider;
  final double? distanceKm;
  final bool actionInFlight;
  final VoidCallback onCall;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onRelease;
  final VoidCallback? onClientCancel;

  const _JobSheet({
    required this.delivery,
    required this.counterpart,
    required this.isRider,
    required this.distanceKm,
    required this.actionInFlight,
    required this.onCall,
    required this.onPrimaryAction,
    this.onRelease,
    this.onClientCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = delivery['status'] as String? ?? 'accepted';
    final name = counterpart?['full_name'] as String? ?? (isRider ? 'Client' : 'Rider');
    final rating = (counterpart?['rating'] as num?)?.toDouble();
    final price = (delivery['price_naira'] as num?)?.toDouble() ?? 0;
    final targetAddress = status == 'accepted'
        ? delivery['pickup_address'] as String? ?? ''
        : delivery['dropoff_address'] as String? ?? '';

    final primaryLabels = {
      'accepted': 'Confirm Pickup',
      'picked_up': 'Start Delivery',
      'in_transit': 'Complete Delivery',
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).padding.bottom + AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        boxShadow: AppShadows.sheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withAlpha(24),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppText.h3.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.h3),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1), style: AppText.bodyMuted),
                        ],
                      ),
                  ],
                ),
              ),
              if (distanceKm != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${distanceKm!.toStringAsFixed(1)} km', style: AppText.h3),
                    Text('away', style: AppText.caption),
                  ],
                ),
              const SizedBox(width: AppSpacing.sm),
              _MapControlButton(icon: Icons.call_rounded, onTap: onCall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(targetAddress,
                    style: AppText.bodyMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text('₦${price.toStringAsFixed(0)}',
                  style: AppText.h3.copyWith(color: AppColors.money)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isRider && primaryLabels.containsKey(status))
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: actionInFlight ? null : onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'in_transit' ? AppColors.success : AppColors.primary,
                ),
                child: actionInFlight
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(primaryLabels[status]!),
              ),
            ),
          if (onRelease != null || onClientCancel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onRelease ?? onClientCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: Text(onRelease != null ? 'Release this job' : 'Cancel delivery'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletionSheet extends StatelessWidget {
  final String destination;
  final double price;
  const _CompletionSheet({required this.destination, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).padding.bottom + AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.success.withAlpha(24), shape: BoxShape.circle),
            child: const Icon(Icons.task_alt_rounded, color: AppColors.success, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Mark as delivered?', style: AppText.h2, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Confirm the package reached $destination.',
              style: AppText.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Confirm Delivery'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not yet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveredSuccessDialog extends StatelessWidget {
  final double price;
  const _DeliveredSuccessDialog({required this.price});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PopIn(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Delivered!', style: AppText.h1),
              const SizedBox(height: AppSpacing.xs),
              Text('+₦${price.toStringAsFixed(0)} added to your earnings',
                  style: AppText.body.copyWith(color: AppColors.money, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
