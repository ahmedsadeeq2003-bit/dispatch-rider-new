import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

/// Reachable by anyone (no separate nav gating), but gated at both layers
/// that matter: this screen checks profiles.role before showing anything,
/// and the admin-* Edge Functions re-check it server-side regardless.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _checkingAccess = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final isAdmin = await AdminService.isCurrentUserAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _checkingAccess = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Admin')),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Admins only',
          subtitle: 'Your account does not have admin access.',
          color: AppColors.danger,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Verifications'),
            Tab(text: 'Companies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_VerificationsTab(), _CompaniesTab()],
      ),
    );
  }
}

class _VerificationsTab extends StatefulWidget {
  const _VerificationsTab();

  @override
  State<_VerificationsTab> createState() => _VerificationsTabState();
}

class _VerificationsTabState extends State<_VerificationsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.listPendingVerifications();
  }

  void _reload() {
    setState(() => _future = AdminService.listPendingVerifications());
  }

  Future<void> _review(String id, String decision) async {
    try {
      await AdminService.reviewVerification(id, decision);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification ${decision}d')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: AppText.bodyMuted),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.verified_user_rounded,
            title: 'No pending verifications',
            subtitle: 'New rider submissions will appear here',
            color: AppColors.success,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _future;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final v = items[i];
              final profile = v['profiles'] as Map<String, dynamic>?;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['full_name'] ?? profile?['full_name'] ?? 'Unknown rider',
                        style: AppText.h3),
                    const SizedBox(height: 4),
                    Text('NIN: ${v['nin']}', style: AppText.bodyMuted),
                    Text('Address: ${v['address']}', style: AppText.bodyMuted),
                    if (v['proof_of_address'] != null)
                      Text('Proof of address: ${v['proof_of_address']}',
                          style: AppText.bodyMuted),
                    if (v['next_of_kin'] != null)
                      Text(
                          'Next of kin: ${v['next_of_kin']} (${v['next_of_kin_relationship'] ?? '—'}) • ${v['next_of_kin_phone'] ?? '—'}',
                          style: AppText.bodyMuted),
                    if (profile?['phone_number'] != null)
                      Text('Phone: ${profile!['phone_number']}',
                          style: AppText.bodyMuted),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _review(v['id'], 'approve'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success),
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _review(v['id'], 'reject'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              foregroundColor: AppColors.danger,
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CompaniesTab extends StatefulWidget {
  const _CompaniesTab();

  @override
  State<_CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<_CompaniesTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.listCompanies();
  }

  void _reload() {
    setState(() => _future = AdminService.listCompanies());
  }

  Future<void> _showCreateDialog() async {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Invite code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Company name'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true) return;
    if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
      return;
    }

    try {
      await AdminService.createCompany(
          codeController.text.trim(), nameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company created')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: AppText.bodyMuted),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.apartment_rounded,
              title: 'No companies yet',
              subtitle: 'Tap + to create one',
              color: AppColors.accentBlue,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final c = items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'] ?? '', style: AppText.h3),
                          Text('Code: ${c['code']} • ${c['plan']}',
                              style: AppText.bodyMuted),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(28),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(c['status'] ?? '',
                            style: AppText.caption
                                .copyWith(color: AppColors.success)),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
