import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final email = _currentUser?.email ?? 'No email';
    final name = _userData?['full_name'] ?? email.split('@').first;
    final phone = _userData?['phone_number'] ?? 'Not provided';
    final role = _userData?['role'] ?? 'client';
    final rating = (_userData?['rating'] as num?)?.toDouble() ?? 5.0;
    final isOnline = _userData?['is_online'] ?? false;
    final joinedDate = _userData?['created_at'] != null
        ? DateTime.parse(_userData!['created_at'] as String)
            .toString()
            .split(' ')
            .first
        : 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withAlpha(24),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Name
                  Text(name, style: AppText.h1),
                  const SizedBox(height: AppSpacing.xs),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      role.toString().toUpperCase(),
                      style: AppText.caption
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Info Cards
                  _buildInfoCard(
                    icon: Icons.email_rounded,
                    title: 'Email',
                    value: email,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoCard(
                    icon: Icons.phone_rounded,
                    title: 'Phone Number',
                    value: phone,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoCard(
                    icon: Icons.star_rounded,
                    title: 'Rating',
                    value: rating.toStringAsFixed(1),
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoCard(
                    icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    title: 'Status',
                    value: isOnline ? 'Online' : 'Offline',
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Joined',
                    value: joinedDate,
                    color: AppColors.accentYellow,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Edit profile coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.caption),
                const SizedBox(height: 4),
                Text(value, style: AppText.h3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
