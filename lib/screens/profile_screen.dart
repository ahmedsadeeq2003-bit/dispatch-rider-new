import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'contact_us_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _currentUser.id)
          .maybeSingle();

      setState(() {
        _userData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().signOut(context);
            },
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _currentUser?.email ?? 'No email';
    final name = _userData?['full_name'] ?? email.split('@').first;
    final phone = _userData?['phone_number'] ?? 'Not provided';
    final role = (_userData?['role'] ?? 'client').toString();
    final rating = (_userData?['rating'] as num?)?.toDouble() ?? 5.0;
    final isOnline = _userData?['is_online'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                FadeSlideIn(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withAlpha(24),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: AppText.display.copyWith(color: AppColors.primary, fontSize: 34),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(name, style: AppText.h1),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(role.toUpperCase(),
                            style: AppText.caption.copyWith(color: AppColors.primaryDark)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (role == 'rider')
                  Row(
                    children: [
                      Expanded(
                          child: _StatTile(
                              icon: Icons.star_rounded,
                              color: AppColors.warning,
                              value: rating.toStringAsFixed(1),
                              label: 'Rating')),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: _StatTile(
                              icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                              color: isOnline ? AppColors.success : AppColors.textMuted,
                              value: isOnline ? 'Online' : 'Offline',
                              label: 'Status')),
                    ],
                  ),
                if (role == 'rider') const SizedBox(height: AppSpacing.lg),

                _SettingsRow(icon: Icons.email_rounded, title: 'Email', value: email),
                _SettingsRow(icon: Icons.phone_rounded, title: 'Phone', value: phone),
                const SizedBox(height: AppSpacing.lg),

                _SettingsRow(
                  icon: Icons.support_agent_rounded,
                  title: 'Contact Support',
                  isLink: true,
                  onTap: () => Navigator.push(
                      context, AppPageRoute(page: const ContactUsScreen())),
                ),
                if (role == 'admin')
                  _SettingsRow(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Panel',
                    isLink: true,
                    onTap: () => Navigator.push(
                        context, AppPageRoute(page: const AdminDashboardScreen())),
                  ),
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  isLink: true,
                  danger: true,
                  onTap: _confirmSignOut,
                ),
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppText.numericMd),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final bool isLink;
  final bool danger;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.isLink = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: danger ? AppColors.danger : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: AppText.body.copyWith(color: color))),
              if (value != null)
                Flexible(
                  child: Text(value!,
                      style: AppText.bodyMuted, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
                ),
              if (isLink)
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
