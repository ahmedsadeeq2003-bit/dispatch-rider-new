import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/voltz_theme.dart';
import '../../widgets/voltz/voltz_stat_tile.dart';

/// Voltz account screen — profile header, stat grid, an Eco Champion
/// highlight banner, and recent activity. Deliveries-completed and
/// total-spent are read from Supabase; CO2 saved is an estimate derived
/// from delivery count (no CO2 tracking exists in the schema yet).
class VoltzAccountScreen extends StatefulWidget {
  const VoltzAccountScreen({super.key});

  @override
  State<VoltzAccountScreen> createState() => _VoltzAccountScreenState();
}

class _VoltzAccountScreenState extends State<VoltzAccountScreen> {
  final User? _user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _recentDeliveries = [];
  int _completedCount = 0;
  double _totalSpent = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final deliveries = await Supabase.instance.client
          .from('deliveries')
          .select('id, status, price_naira, pickup_address, dropoff_address, created_at')
          .eq('client_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      final rows = List<Map<String, dynamic>>.from(deliveries as List);
      final completed = rows.where((d) => d['status'] == 'completed').toList();

      setState(() {
        _profile = profile;
        _recentDeliveries = rows.take(5).toList();
        _completedCount = completed.length;
        _totalSpent = completed.fold<double>(
          0,
          (sum, d) => sum + ((d['price_naira'] as num?)?.toDouble() ?? 0),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading account: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? 'No email';
    final name = (_profile?['full_name'] as String?)?.trim().isNotEmpty == true
        ? _profile!['full_name'] as String
        : email.split('@').first;
    final memberSince = _memberSince();
    // ~1.1kg CO2 saved per delivery vs. an equivalent solo car trip —
    // an estimate for the eco banner, not a measured figure.
    final co2Kg = _completedCount * 1.1;

    return Theme(
      data: VoltzTheme.dark,
      child: Scaffold(
        backgroundColor: VoltzColors.background,
        appBar: AppBar(title: const Text('Account')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VoltzColors.neon))
            : RefreshIndicator(
                color: VoltzColors.neon,
                backgroundColor: VoltzColors.surface,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(VoltzSpacing.md),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: VoltzColors.neon.withAlpha(28),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: VoltzText.display.copyWith(color: VoltzColors.neon, fontSize: 30),
                            ),
                          ),
                          const SizedBox(height: VoltzSpacing.sm),
                          Text(name, style: VoltzText.h1),
                          const SizedBox(height: 2),
                          Text(email, style: VoltzText.bodyMuted),
                          const SizedBox(height: VoltzSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: VoltzColors.neon.withAlpha(24),
                              borderRadius: BorderRadius.circular(VoltzSpacing.radiusPill),
                              border: Border.all(color: VoltzColors.neon.withAlpha(90)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.eco_rounded, size: 14, color: VoltzColors.neon),
                                const SizedBox(width: 4),
                                Text('Eco Champion',
                                    style: VoltzText.caption.copyWith(
                                        color: VoltzColors.neon, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VoltzSpacing.xl),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: VoltzSpacing.sm,
                      crossAxisSpacing: VoltzSpacing.sm,
                      childAspectRatio: 1.5,
                      children: [
                        VoltzStatTile(
                          icon: Icons.local_shipping_rounded,
                          value: '$_completedCount',
                          label: 'Total deliveries',
                        ),
                        VoltzStatTile(
                          icon: Icons.eco_rounded,
                          value: '${co2Kg.toStringAsFixed(1)} kg',
                          label: 'Total CO2 saved',
                        ),
                        VoltzStatTile(
                          icon: Icons.payments_rounded,
                          value: '₦${_totalSpent.toStringAsFixed(0)}',
                          label: 'Total spent',
                          accent: VoltzColors.info,
                        ),
                        VoltzStatTile(
                          icon: Icons.calendar_month_rounded,
                          value: memberSince,
                          label: 'Member since',
                          accent: VoltzColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: VoltzSpacing.lg),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(VoltzSpacing.md),
                      decoration: BoxDecoration(
                        color: VoltzColors.neon.withAlpha(18),
                        borderRadius: BorderRadius.circular(VoltzSpacing.radiusLg),
                        border: Border.all(color: VoltzColors.neon.withAlpha(70)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: VoltzColors.neon,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.eco_rounded, color: VoltzColors.surfaceSunken),
                          ),
                          const SizedBox(width: VoltzSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You\'re an Eco Champion', style: VoltzText.h3),
                                const SizedBox(height: 2),
                                Text(
                                  'Choosing shared delivery routes has saved an estimated ${co2Kg.toStringAsFixed(1)} kg of CO2.',
                                  style: VoltzText.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VoltzSpacing.xl),

                    Text('Recent activity', style: VoltzText.h2),
                    const SizedBox(height: VoltzSpacing.sm),
                    if (_recentDeliveries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(VoltzSpacing.lg),
                        decoration: BoxDecoration(
                          color: VoltzColors.surface,
                          borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
                          border: Border.all(color: VoltzColors.border),
                        ),
                        child: Center(
                          child: Text('No deliveries yet', style: VoltzText.bodyMuted),
                        ),
                      )
                    else
                      ..._recentDeliveries.map((d) => _ActivityRow(delivery: d)),
                  ],
                ),
              ),
      ),
    );
  }

  String _memberSince() {
    final raw = _profile?['created_at'] as String? ?? _user?.createdAt;
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> delivery;
  const _ActivityRow({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final status = (delivery['status'] as String?) ?? 'pending';
    final dropoff = (delivery['dropoff_address'] as String?) ?? 'Unknown destination';
    final price = (delivery['price_naira'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: VoltzSpacing.sm),
      padding: const EdgeInsets.all(VoltzSpacing.md),
      decoration: BoxDecoration(
        color: VoltzColors.surface,
        borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
        border: Border.all(color: VoltzColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VoltzColors.surfaceRaised,
              borderRadius: BorderRadius.circular(VoltzSpacing.radiusSm),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 18, color: VoltzColors.textSecondary),
          ),
          const SizedBox(width: VoltzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dropoff, style: VoltzText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  status.replaceAll('_', ' '),
                  style: VoltzText.caption.copyWith(color: VoltzColors.textMuted),
                ),
              ],
            ),
          ),
          if (price != null)
            Text('₦${price.toStringAsFixed(0)}', style: VoltzText.caption.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
