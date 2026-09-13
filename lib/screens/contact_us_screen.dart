import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchEmail() async {
    final uri =
        Uri.parse('mailto:support@senditt.com?subject=Support%20Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:+2348012345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/2348012345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Contact Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text("We'd love to hear from you!", style: AppText.h1),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reach out to us for support, feedback, or business inquiries.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Contact Options
            _buildContactCard(
              context,
              icon: Icons.email_rounded,
              title: 'Email Us',
              subtitle: 'support@senditt.com',
              color: AppColors.info,
              onTap: _launchEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildContactCard(
              context,
              icon: Icons.phone_rounded,
              title: 'Call Us',
              subtitle: '+234 801 234 5678',
              color: AppColors.success,
              onTap: _launchPhone,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildContactCard(
              context,
              icon: Icons.chat_rounded,
              title: 'WhatsApp',
              subtitle: 'Chat with us on WhatsApp',
              color: AppColors.tertiary,
              onTap: _launchWhatsApp,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Business Hours
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Business Hours', style: AppText.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildHoursRow('Monday - Friday', '8:00 AM - 6:00 PM'),
                  _buildHoursRow('Saturday', '9:00 AM - 4:00 PM'),
                  _buildHoursRow('Sunday', 'Closed'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // FAQ Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQ section coming soon!')),
                  );
                },
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Frequently Asked Questions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.bodyMuted),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppText.bodyMuted),
          Text(hours, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
