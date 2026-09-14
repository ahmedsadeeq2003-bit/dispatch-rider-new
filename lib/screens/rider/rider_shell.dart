import 'package:flutter/material.dart';
import '../profile_screen.dart';
import 'rider_home_tab.dart';
import 'rider_jobs_tab.dart';
import 'earnings_screen.dart';

/// Root shell for a signed-in rider: bottom navigation across Home / Jobs /
/// Earnings / Profile. Replaces the old single-screen 2x2 grid dashboard —
/// each tab keeps its own state via IndexedStack (switching tabs doesn't
/// restart a stream or lose scroll position).
class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _index = 0;

  final List<Widget> _tabs = const [
    RiderHomeTab(),
    RiderJobsTab(),
    EarningsScreen(embedded: true),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            selectedIcon: Icon(Icons.delivery_dining_rounded),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
