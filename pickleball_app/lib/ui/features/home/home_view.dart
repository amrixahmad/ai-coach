import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/supabase_service.dart';
import '../results/results_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  File? _selectedVideo;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  Future<void> _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _selectedVideo = File(file.path);
      });
    }
  }

  Future<void> _analyzeVideo() async {
    if (_selectedVideo == null) return;

    setState(() => _isUploading = true);
    try {
      final token = SupabaseService().currentAccessToken;
      final result = await _apiService.processVideo(_selectedVideo!, authToken: token);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultsView(
              videoFile: _selectedVideo!,
              analysisResult: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Pickleball Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => SupabaseService().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload a Stroke or Rally Clip',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Get pro feedback on your dinks, serves, and kitchen positioning.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.shade200, width: 2, style: BorderStyle.solid),
                    ),
                    child: _selectedVideo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 72, color: Colors.indigo[400]),
                              const SizedBox(height: 16),
                              const Text('Select Video from Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('MP4, MOV supported', style: TextStyle(color: Colors.grey[500])),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
                              const SizedBox(height: 16),
                              Text('Video Selected!', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _pickVideo,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Change Video'),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedVideo != null)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _analyzeVideo,
                  icon: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.analytics_outlined, color: Colors.white),
                  label: Text(_isUploading ? 'Analyzing Form...' : 'Analyze Form', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
