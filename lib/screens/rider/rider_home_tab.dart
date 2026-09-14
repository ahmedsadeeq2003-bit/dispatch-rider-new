import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/delivery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../track_order_screen.dart';
import '../pending_deliveries_screen.dart';

/// The application shell's Home tab.
///
/// Composition (this is the whole point of this rewrite): a full-bleed map
/// IS the screen, not a widget placed inside one. Everything else — status,
/// current job, earnings, the one primary action — lives in a real
/// DraggableScrollableSheet layered on top, snapping between a compact
/// collapsed state and a fully expanded one. Nothing here is a dashboard of
/// stacked cards; the sheet reveals more detail only as it's dragged open.
class RiderHomeTab extends StatefulWidget {
  const RiderHomeTab({super.key});

  @override
  State<RiderHomeTab> createState() => _RiderHomeTabState();
}

class _RiderHomeTabState extends State<RiderHomeTab> {
  final _client = Supabase.instance.client;
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();

  static const double _sheetMin = 0.24;
  static const double _sheetMid = 0.55;
  static const double _sheetMax = 0.9;

  String? _riderId;
  Map<String, dynamic>? _profile;
  bool _togglingOnline = false;
  LatLng? _myPosition;

  static const LatLng _fallbackCenter = LatLng(9.0765, 7.3986); // Abuja

  @override
  void initState() {
    super.initState();
    _riderId = _client.auth.currentUser?.id;
    _loadProfile();
    _locateSelf();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
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
      _mapController.move(_myPosition!, 15);
    } catch (_) {
      // Map just stays on the fallback center — location is best-effort here.
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
      _sheetController.animateTo(_sheetMin,
          duration: AppMotion.base, curve: AppMotion.standard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _togglingOnline = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _recenter() {
    if (_myPosition != null) {
      _mapController.move(_myPosition!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _profile?['is_online'] == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ---- Layer 1: the map IS the screen -------------------------------
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _myPosition ?? _fallbackCenter,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.dispatch_rider_new',
            ),
            if (_myPosition != null)
              MarkerLayer(markers: [
                Marker(
                  point: _myPosition!,
                  width: 46,
                  height: 46,
                  child: _SelfMarker(isOnline: isOnline),
                ),
              ]),
          ],
        ),

        // ---- Layer 2: minimal floating chrome over the map ----------------
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GreetingChip(name: _profile?['full_name'] as String?),
                _MapFab(icon: Icons.my_location_rounded, onTap: _recenter),
              ],
            ),
          ),
        ),

        // ---- Layer 3: the real draggable sheet -----------------------------
        if (_riderId != null)
          StreamBuilder<Map<String, dynamic>?>(
            stream: DeliveryService.getMyCurrentJob(_riderId!),
            builder: (context, jobSnapshot) {
              final job = jobSnapshot.data;
              return DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: _sheetMin,
                minChildSize: _sheetMin,
                maxChildSize: _sheetMax,
                snap: true,
                snapSizes: const [_sheetMin, _sheetMid, _sheetMax],
                builder: (context, scrollController) {
                  return _HomeSheet(
                    scrollController: scrollController,
                    riderId: _riderId!,
                    profile: _profile,
                    isOnline: isOnline,
                    togglingOnline: _togglingOnline,
                    job: job,
                    onToggleOnline: _toggleOnline,
                    onExpand: () => _sheetController.animateTo(_sheetMid,
                        duration: AppMotion.base, curve: AppMotion.standard),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

// ============================================================================
// Floating chrome
// ============================================================================

class _GreetingChip extends StatelessWidget {
  final String? name;
  const _GreetingChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final first = (name?.trim().isNotEmpty ?? false) ? name!.trim().split(' ').first : 'Rider';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.mapControlSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.waving_hand_rounded, size: 15, color: AppColors.warning),
          const SizedBox(width: 6),
          Text('Hey, $first', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mapControlSurface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.card),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _SelfMarker extends StatelessWidget {
  final bool isOnline;
  const _SelfMarker({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isOnline ? AppColors.online : AppColors.offline,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8)],
      ),
      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
    );
  }
}

// ============================================================================
// The sheet — one primary action, progressive disclosure below it.
// ============================================================================

class _HomeSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String riderId;
  final Map<String, dynamic>? profile;
  final bool isOnline;
  final bool togglingOnline;
  final Map<String, dynamic>? job;
  final VoidCallback onToggleOnline;
  final VoidCallback onExpand;

  const _HomeSheet({
    required this.scrollController,
    required this.riderId,
    required this.profile,
    required this.isOnline,
    required this.togglingOnline,
    required this.job,
    required this.onToggleOnline,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        boxShadow: AppShadows.sheet,
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, MediaQuery.of(context).padding.bottom + AppSpacing.xl),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Job takes over the sheet the instant one exists — it dominates,
          // per "prioritize the active delivery above everything else".
          if (job != null)
            _ActiveJobSection(job: job!)
          else if (!isOnline)
            _OfflineSection(loading: togglingOnline, onGoOnline: onToggleOnline)
          else
            _OnlineIdleSection(
              riderId: riderId,
              loading: togglingOnline,
              onGoOffline: onToggleOnline,
              onExpand: onExpand,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATE: offline
// ---------------------------------------------------------------------------
class _OfflineSection extends StatelessWidget {
  final bool loading;
  final VoidCallback onGoOnline;
  const _OfflineSection({required this.loading, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(color: AppColors.offline, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text("You're offline", style: AppText.h2),
          ],
        ),
        const SizedBox(height: 4),
        Text('Go online to start receiving delivery requests nearby.',
            style: AppText.bodyMuted),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: loading ? null : onGoOnline,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.signal),
            child: loading
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Go Online'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STATE: online, no active job — reveals more only as the sheet is dragged
// ---------------------------------------------------------------------------
class _OnlineIdleSection extends StatelessWidget {
  final String riderId;
  final bool loading;
  final VoidCallback onGoOffline;
  final VoidCallback onExpand;

  const _OnlineIdleSection({
    required this.riderId,
    required this.loading,
    required this.onGoOffline,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: AppColors.online, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text("You're online", style: AppText.h2),
              ],
            ),
            Switch(
              value: true,
              onChanged: loading ? null : (_) => onGoOffline(),
              activeThumbColor: AppColors.online,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DeliveryService.getPendingDeliveries(),
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            if (count == 0) {
              return _WaitingRow();
            }
            return _IncomingRow(count: count);
          },
        ),

        const SizedBox(height: AppSpacing.xl),
        Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text('TODAY', style: AppText.label),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DeliveryService.getCompletedDeliveries(riderId),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final now = DateTime.now();
            final todays = all.where((d) {
              final dt = DateTime.tryParse(d['completed_at'] as String? ?? '')?.toLocal();
              return dt != null && dt.year == now.year && dt.month == now.month && dt.day == now.day;
            }).toList();
            final earnings = todays.fold<double>(
                0, (s, d) => s + ((d['price_naira'] as num?)?.toDouble() ?? 0));
            return Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.money),
                const SizedBox(width: 6),
                Text('₦${earnings.toStringAsFixed(0)} earned', style: AppText.body),
                const SizedBox(width: AppSpacing.lg),
                Icon(Icons.task_alt_rounded, size: 16, color: AppColors.accentPurple),
                const SizedBox(width: 6),
                Text('${todays.length} deliveries', style: AppText.body),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WaitingRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.info.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Icons.podcasts_rounded, color: AppColors.info, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Waiting for delivery requests', style: AppText.h3),
              Text('We\'ll notify you the moment one comes in', style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomingRow extends StatelessWidget {
  final int count;
  const _IncomingRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.signal.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.signal, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count ${count == 1 ? 'request' : 'requests'} nearby', style: AppText.h3),
                Text('Ready for you to accept', style: AppText.caption),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              AppPageRoute(page: const PendingDeliveriesScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.signal,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATE: active job — one primary action, key facts, nothing else.
// ---------------------------------------------------------------------------
class _ActiveJobSection extends StatelessWidget {
  final Map<String, dynamic> job;
  const _ActiveJobSection({required this.job});

  static const _stageLabels = {
    'accepted': 'Heading to pickup',
    'picked_up': 'Package collected',
    'in_transit': 'On the way to destination',
  };

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String? ?? 'accepted';
    final pickup = job['pickup_address'] as String? ?? '';
    final destination = job['dropoff_address'] as String? ?? '';
    final price = (job['price_naira'] as num?)?.toDouble() ?? 0.0;
    final id = job['id'] as String? ?? '';
    final targetAddress = status == 'accepted' ? pickup : destination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text('ACTIVE', style: AppText.label.copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(_stageLabels[status] ?? status,
                  style: AppText.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(status == 'accepted' ? Icons.circle : Icons.location_on_rounded,
                size: 16, color: status == 'accepted' ? AppColors.accentGreen : AppColors.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(targetAddress, style: AppText.body)),
            Text('₦${price.toStringAsFixed(0)}',
                style: AppText.h3.copyWith(color: AppColors.money)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              AppPageRoute(page: TrackOrderScreen(orderId: id)),
            ),
            icon: const Icon(Icons.navigation_rounded),
            label: const Text('Continue Delivery'),
          ),
        ),
      ],
    );
  }
}
