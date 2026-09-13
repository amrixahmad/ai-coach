import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  int _totalSessions = 0;
  int _totalShots = 0;
  int _goodShots = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final token = _authService.accessToken;
      final analyses = await _apiService.getAnalyses(authToken: token);
      
      int totalShotsCount = 0;
      int goodShotsCount = 0;

      for (final a in analyses) {
        final strokes = a.analysisResult.analysis.strokes;
        totalShotsCount += strokes.length;
        goodShotsCount += strokes.where((s) => s.result == 'good' || s.result == 'made').length;
      }

      if (mounted) {
        setState(() {
          _totalSessions = analyses.length;
          _totalShots = totalShotsCount;
          _goodShots = goodShotsCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final accuracyRate = _totalShots > 0 ? ((_goodShots / _totalShots) * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Stats', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.person, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.email ?? 'Pickleball Player',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PRO MEMBER',
                                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Performance Stats', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Stat Grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Sessions',
                          value: '$_totalSessions',
                          icon: Icons.video_library_rounded,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Shots Analyzed',
                          value: '$_totalShots',
                          icon: Icons.analytics_rounded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Form Accuracy',
                          value: '$accuracyRate%',
                          icon: Icons.thumb_up_alt_rounded,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Good Form Shots',
                          value: '$_goodShots',
                          icon: Icons.check_circle_rounded,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  // Account Actions
                  Text('Account Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: Colors.indigo),
                          title: const Text('Dev Bypass Mode'),
                          subtitle: const Text('Active (Phase 1 Testing)'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          onTap: () => _authService.signOut(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
