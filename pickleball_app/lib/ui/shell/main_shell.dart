import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/history/history_view.dart';
import '../features/home/home_view.dart';
import '../features/profile/profile_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    HistoryView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _restoreActiveTab();
  }

  Future<void> _restoreActiveTab() async {
    try {
      final fragment = Uri.base.fragment.toLowerCase();
      final tabParam = Uri.base.queryParameters['tab']?.toLowerCase();
      
      if (fragment.contains('history') || tabParam == 'history') {
        if (mounted) setState(() => _currentIndex = 1);
        return;
      } else if (fragment.contains('profile') || tabParam == 'profile') {
        if (mounted) setState(() => _currentIndex = 2);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedTab = prefs.getInt('last_active_tab');
      if (savedTab != null && savedTab >= 0 && savedTab < _pages.length) {
        if (mounted) {
          setState(() => _currentIndex = savedTab);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Failed to restore active tab: $e');
    }
  }

  void _onTabSelected(int index) async {
    setState(() {
      _currentIndex = index;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_active_tab', index);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam_rounded),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
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
