import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/delivery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/online_toggle.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/motion.dart';
import '../track_order_screen.dart';

/// The rider's front door: answers "am I online", "do I have an active job",
/// and "how am I doing today" in one glance, before anything else.
class RiderHomeTab extends StatefulWidget {
  const RiderHomeTab({super.key});

  @override
  State<RiderHomeTab> createState() => _RiderHomeTabState();
}

class _RiderHomeTabState extends State<RiderHomeTab> {
  final _client = Supabase.instance.client;
  String? _riderId;
  Map<String, dynamic>? _profile;
  bool _togglingOnline = false;
  LatLng? _myPosition;

  @override
  void initState() {
    super.initState();
    _riderId = _client.auth.currentUser?.id;
    _loadProfile();
    _locateSelf();
  }

  Future<void> _loadProfile() async {
    if (_riderId == null) return;
    final profile = await DeliveryService.getMyProfile(_riderId!);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _locateSelf() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _myPosition = LatLng(position.latitude, position.longitude));
    } catch (_) {
      // Silently fall back to the offline hero illustration — location is a
      // nice-to-have on this screen, not a blocker.
    }
  }

  Future<void> _toggleOnline() async {
    if (_riderId == null || _profile == null) return;
    final current = _profile!['is_online'] == true;
    setState(() => _togglingOnline = true);
    try {
      await DeliveryService.setOnlineStatus(_riderId!, !current);
      if (!mounted) return;
      setState(() {
        _profile = {..._profile!, 'is_online': !current};
        _togglingOnline = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _togglingOnline = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _profile?['is_online'] == true;
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 5.0;
    final totalDeliveries = _profile?['total_deliveries'] as int? ?? 0;
    final name = _profile?['full_name'] as String? ?? 'Rider';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          await _locateSelf();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hey, ${name.split(' ').first} 👋', style: AppText.h1),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text('${rating.toStringAsFixed(1)} rating', style: AppText.bodyMuted),
                        Text('  •  $totalDeliveries trips', style: AppText.bodyMuted),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            FadeSlideIn(
              child: OnlineToggle(
                isOnline: isOnline,
                loading: _togglingOnline,
                onTap: _toggleOnline,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Active job spotlight — dominates the screen when it exists,
            // per "prioritize the active delivery above everything else".
            if (_riderId != null)
              StreamBuilder<Map<String, dynamic>?>(
                stream: DeliveryService.getMyCurrentJob(_riderId!),
                builder: (context, snapshot) {
                  final job = snapshot.data;
                  if (job == null) return const SizedBox.shrink();
                  return FadeSlideIn(child: _ActiveJobSpotlight(job: job));
                },
              ),
            const SizedBox(height: AppSpacing.lg),

            SectionHeader(title: 'Today'),
            const SizedBox(height: AppSpacing.sm),
            if (_riderId != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: DeliveryService.getCompletedDeliveries(_riderId!),
                builder: (context, snapshot) {
                  final all = snapshot.data ?? [];
                  final today = DateTime.now();
                  final todays = all.where((d) {
                    final completedAt = d['completed_at'] as String?;
                    if (completedAt == null) return false;
                    final dt = DateTime.tryParse(completedAt)?.toLocal();
                    return dt != null &&
                        dt.year == today.year &&
                        dt.month == today.month &&
                        dt.day == today.day;
                  }).toList();
                  final earnings = todays.fold<double>(
                      0, (sum, d) => sum + ((d['price_naira'] as num?)?.toDouble() ?? 0));

                  return Row(
                    children: [
                      Expanded(
                        child: StatChip(
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.money,
                          value: '₦${earnings.toStringAsFixed(0)}',
                          label: 'Earned today',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatChip(
                          icon: Icons.task_alt_rounded,
                          color: AppColors.accentPurple,
                          value: '${todays.length}',
                          label: 'Deliveries',
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: AppSpacing.lg),

            SectionHeader(title: 'Your area'),
            const SizedBox(height: AppSpacing.sm),
            _AreaMapPreview(position: _myPosition, isOnline: isOnline),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobSpotlight extends StatelessWidget {
  final Map<String, dynamic> job;
  const _ActiveJobSpotlight({required this.job});

  @override
  Widget build(BuildContext context) {
    final pickup = job['pickup_address'] as String? ?? '';
    final destination = job['dropoff_address'] as String? ?? '';
    final status = job['status'] as String? ?? 'accepted';
    final price = (job['price_naira'] as num?)?.toDouble() ?? 0.0;
    final id = job['id'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppPageRoute(page: TrackOrderScreen(orderId: id)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppGradients.heroBrand,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: AppShadows.floating,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE DELIVERY',
                    style: AppText.label.copyWith(color: Colors.white.withAlpha(210))),
                StatusBadge(status: status, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(destination, style: AppText.h2.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text('From $pickup',
                style: AppText.bodyMuted.copyWith(color: Colors.white.withAlpha(210)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₦${price.toStringAsFixed(0)}',
                    style: AppText.numericMd.copyWith(color: Colors.white)),
                Row(
                  children: [
                    Text('Continue', style: AppText.button.copyWith(color: Colors.white)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaMapPreview extends StatelessWidget {
  final LatLng? position;
  final bool isOnline;
  const _AreaMapPreview({required this.position, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, color: AppColors.textMuted, size: 28),
              const SizedBox(height: AppSpacing.xs),
              Text('Location unavailable', style: AppText.bodyMuted),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(initialCenter: position!, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.dispatch_rider_new',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: position!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOnline ? AppColors.online : AppColors.offline,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  isOnline ? 'Visible to nearby jobs' : 'Offline',
                  style: AppText.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
