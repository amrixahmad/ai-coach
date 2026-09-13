import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../results/results_view.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<SavedAnalysis> _analyses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authService.accessToken;
      final list = await _apiService.getAnalyses(authToken: token);
      if (mounted) {
        setState(() {
          _analyses = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final token = _authService.accessToken;
      await _apiService.deleteAnalysis(id, authToken: token);
      setState(() {
        _analyses.removeWhere((item) => item.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _openResults(SavedAnalysis item) {
    final videoPath = item.videoUrl ?? 'upload.mp4';
    final dummyXFile = XFile(videoPath, name: videoPath.split('/').last);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsView(
          videoFile: dummyXFile,
          analysisResult: item.analysisResult,
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Recent Analysis';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Coaching Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading history: $_errorMessage'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchHistory, child: const Text('Retry')),
                    ],
                  ),
                )
              : _analyses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No past video analyses found',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload a pickleball video on the Home screen to get started!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _analyses.length,
                      itemBuilder: (context, index) {
                        final item = _analyses[index];
                        final strokes = item.analysisResult.analysis.strokes;
                        final goodCount = strokes.where((s) => s.result == 'good' || s.result == 'made').length;
                        final needsImpCount = strokes.length - goodCount;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openResults(item),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.sports_tennis, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(item.createdAt),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () => _deleteItem(item.id),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (goodCount > 0)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$goodCount Good Form',
                                            style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      if (needsImpCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$needsImpCount Needs Improvement',
                                            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const [
                                      Text(
                                        'Replay Session',
                                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blueAccent),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
