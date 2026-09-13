import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../history/history_view.dart';
import '../results/results_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  XFile? _selectedVideo;
  VideoPlayerController? _previewController;
  String _fileSizeMb = '0.0';
  bool _isUploading = false;
  int _analysisStage = 0; // 0: Idle, 1: Uploading, 2: Tracking, 3: AI Analysis

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      _previewController?.dispose();
      _previewController = null;

      double sizeMb = 0.0;
      try {
        final length = await file.length();
        sizeMb = length / (1024 * 1024);
      } catch (_) {}

      VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
      } else {
        controller = VideoPlayerController.file(File(file.path));
      }

      await controller.initialize();
      controller.setVolume(0.0);
      controller.setLooping(true);
      controller.play();

      if (mounted) {
        setState(() {
          _selectedVideo = file;
          _previewController = controller;
          _fileSizeMb = sizeMb.toStringAsFixed(1);
        });
      }
    }
  }

  void _clearVideo() {
    _previewController?.dispose();
    setState(() {
      _selectedVideo = null;
      _previewController = null;
      _fileSizeMb = '0.0';
    });
  }

  Future<void> _analyzeVideo() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isUploading = true;
      _analysisStage = 1;
    });

    final timer1 = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && _isUploading) setState(() => _analysisStage = 2);
    });
    final timer2 = Timer(const Duration(milliseconds: 5500), () {
      if (mounted && _isUploading) setState(() => _analysisStage = 3);
    });

    try {
      final token = AuthService().accessToken;
      final result = await _apiService.processVideo(_selectedVideo!, authToken: token);

      timer1.cancel();
      timer2.cancel();

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
      timer1.cancel();
      timer2.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _analysisStage = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Pickleball Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Past Sessions',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload a Stroke or Rally Clip',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Get pro feedback on your dinks, serves, and kitchen positioning.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Video Upload & Preview Dropzone Container
              if (_selectedVideo == null)
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.teal.shade300, width: 2, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.teal.shade800),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select Pickleball Clip from Gallery',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text('MP4, MOV vertical/horizontal clips supported', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                // Video Preview Card with Metadata & Controls
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.teal, size: 20),
                                SizedBox(width: 6),
                                Text('Clip Ready for Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: _clearVideo,
                              tooltip: 'Clear Video',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Video Player Preview Canvas
                        if (_previewController != null && _previewController!.value.isInitialized)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 220,
                              width: double.infinity,
                              color: Colors.black,
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: _previewController!.value.aspectRatio,
                                  child: VideoPlayer(_previewController!),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: CircularProgressIndicator()),
                          ),

                        const SizedBox(height: 12),
                        // Metadata Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedVideo!.name.isNotEmpty ? _selectedVideo!.name : 'pickleball_rally.mp4',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$_fileSizeMb MB',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Choose Different Clip'),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Multi-stage Analysis Progress Display
              if (_isUploading)
                Card(
                  elevation: 3,
                  color: Colors.teal.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.tealAccent, strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _analysisStage == 1
                                  ? 'Stage 1/3: Uploading Video...'
                                  : _analysisStage == 2
                                      ? 'Stage 2/3: Biomechanical Pose Tracking...'
                                      : 'Stage 3/3: Gemini AI Form Analysis...',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: _analysisStage == 1 ? 0.33 : _analysisStage == 2 ? 0.66 : 0.95,
                          backgroundColor: Colors.teal.shade700,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _analysisStage == 1
                              ? 'Sending video file to local processing pipeline...'
                              : _analysisStage == 2
                                  ? 'Extracting elbow angle & knee squat depth with MediaPipe...'
                                  : 'Generating pro coaching recommendations on your strokes...',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_selectedVideo != null)
                ElevatedButton.icon(
                  onPressed: _analyzeVideo,
                  icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                  label: const Text('Analyze Form & Get Coaching', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

