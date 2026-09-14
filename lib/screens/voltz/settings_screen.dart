import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';

/// Voltz settings — Notifications / Privacy / Account, matching the dark
/// bordered-card conventions of the rest of the Voltz screens.
class VoltzSettingsScreen extends StatefulWidget {
  const VoltzSettingsScreen({super.key});

  @override
  State<VoltzSettingsScreen> createState() => _VoltzSettingsScreenState();
}

class _VoltzSettingsScreenState extends State<VoltzSettingsScreen> {
  bool _deliveryUpdates = true;
  bool _ecoReports = true;
  bool _shareLiveLocation = true;
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: VoltzTheme.dark,
      child: Scaffold(
        backgroundColor: VoltzColors.background,
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(VoltzSpacing.md),
          children: [
            _SectionLabel('NOTIFICATIONS'),
            _SettingsGroup(children: [
              _ToggleRow(
                icon: Icons.local_shipping_outlined,
                title: 'Delivery updates',
                subtitle: 'Status changes on your active deliveries',
                value: _deliveryUpdates,
                onChanged: (v) => setState(() => _deliveryUpdates = v),
              ),
              _ToggleRow(
                icon: Icons.eco_outlined,
                title: 'Eco impact reports',
                subtitle: 'Weekly summary of CO2 saved',
                value: _ecoReports,
                onChanged: (v) => setState(() => _ecoReports = v),
                isLast: true,
              ),
            ]),
            const SizedBox(height: VoltzSpacing.lg),

            _SectionLabel('PRIVACY'),
            _SettingsGroup(children: [
              _ToggleRow(
                icon: Icons.location_on_outlined,
                title: 'Share live location',
                subtitle: 'Let riders and clients track deliveries in real time',
                value: _shareLiveLocation,
                onChanged: (v) => setState(() => _shareLiveLocation = v),
              ),
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                subtitle: 'Voltz always runs dark for now',
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                isLast: true,
              ),
            ]),
            const SizedBox(height: VoltzSpacing.lg),

            _SectionLabel('ACCOUNT'),
            _SettingsGroup(children: [
              _LinkRow(
                icon: Icons.credit_card_outlined,
                title: 'Payment methods',
                onTap: () => _notImplemented(context),
              ),
              _LinkRow(
                icon: Icons.book_outlined,
                title: 'Address book',
                onTap: () => _notImplemented(context),
              ),
              _LinkRow(
                icon: Icons.help_outline_rounded,
                title: 'Help & support',
                onTap: () => _notImplemented(context),
              ),
              _LinkRow(
                icon: Icons.description_outlined,
                title: 'Terms & privacy',
                onTap: () => _notImplemented(context),
                isLast: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: VoltzSpacing.sm),
      child: Text(text, style: VoltzText.label),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VoltzColors.surface,
        borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
        border: Border.all(color: VoltzColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VoltzSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: VoltzColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: VoltzColors.textSecondary),
          const SizedBox(width: VoltzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VoltzText.body),
                const SizedBox(height: 2),
                Text(subtitle, style: VoltzText.caption),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: VoltzSpacing.md, vertical: 14),
          decoration: BoxDecoration(
            border: isLast ? null : const Border(bottom: BorderSide(color: VoltzColors.border)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: VoltzColors.textSecondary),
              const SizedBox(width: VoltzSpacing.md),
              Expanded(child: Text(title, style: VoltzText.body)),
              const Icon(Icons.chevron_right_rounded, color: VoltzColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
