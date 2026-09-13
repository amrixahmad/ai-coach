import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/tracking_frame.dart';
import '../../../data/services/api_service.dart';
import 'pose_painter.dart';

class ResultsView extends StatefulWidget {
  final XFile videoFile;
  final AnalysisResult analysisResult;

  const ResultsView({
    super.key,
    required this.videoFile,
    required this.analysisResult,
  });

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  late VideoPlayerController _controller;
  TrackingFrame? _currentTrackingFrame;
  int? _selectedStrokeIndex;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final url = widget.analysisResult.videoUrl ?? widget.videoFile.path;
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoFile.path));
    }

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      }
    });

    _controller.addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (!_controller.value.isInitialized) return;
    final currentSeconds = _controller.value.position.inMilliseconds / 1000.0;
    
    final trackingList = widget.analysisResult.tracking;
    if (trackingList.isEmpty) return;

    TrackingFrame closest = trackingList.first;
    double minDiff = (closest.timestamp - currentSeconds).abs();

    for (final frame in trackingList) {
      final diff = (frame.timestamp - currentSeconds).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = frame;
      }
    }

    if (_currentTrackingFrame != closest) {
      setState(() {
        _currentTrackingFrame = closest;
      });
    }
  }

  Duration _parseTimestamp(String raw) {
    try {
      final parts = raw.trim().split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final secondsDouble = double.tryParse(parts[1]) ?? 0.0;
        final milliseconds = (minutes * 60 * 1000) + (secondsDouble * 1000).round();
        return Duration(milliseconds: milliseconds);
      } else if (parts.length == 1) {
        final secondsDouble = double.tryParse(parts[0]) ?? 0.0;
        return Duration(milliseconds: (secondsDouble * 1000).round());
      }
    } catch (_) {}
    return Duration.zero;
  }

  void _seekToStroke(int index, String timestampStr) {
    if (!_controller.value.isInitialized) return;
    final target = _parseTimestamp(timestampStr);
    _controller.seekTo(target);
    _controller.play();
    setState(() {
      _selectedStrokeIndex = index;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strokes = widget.analysisResult.analysis.strokes;
    final maxHeight = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroke Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Video Player Container constrained for Vertical (9:16) & Landscape videos
          if (_controller.value.isInitialized)
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: maxHeight),
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    children: [
                      VideoPlayer(_controller),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PosePainter(currentFrame: _currentTrackingFrame),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Stroke Breakdown List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stroke Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: strokes.isEmpty
                        ? const Center(child: Text('No stroke analysis returned.'))
                        : ListView.builder(
                            itemCount: strokes.length,
                            itemBuilder: (context, index) {
                              final stroke = strokes[index];
                              final isGood = stroke.result == 'good' || stroke.result == 'made';
                              final isIllegal = stroke.result == 'illegal_serve';

                              final badgeBg = isGood
                                  ? Colors.green.shade100
                                  : isIllegal
                                      ? Colors.purple.shade100
                                      : Colors.red.shade100;
                              final badgeTextColor = isGood
                                  ? Colors.green.shade900
                                  : isIllegal
                                      ? Colors.purple.shade900
                                      : Colors.red.shade900;
                              final badgeText = isGood
                                  ? 'GOOD FORM'
                                  : isIllegal
                                      ? 'ILLEGAL SERVE'
                                      : 'NEEDS IMPROVEMENT';

                              final isSelected = _selectedStrokeIndex == index;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _seekToStroke(index, stroke.timestampOfOutcome),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: TextStyle(
                                                  color: badgeTextColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.play_circle_fill_rounded,
                                                  size: 18,
                                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  stroke.timestampOfOutcome,
                                                  style: TextStyle(
                                                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(stroke.shotType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(stroke.feedback, style: TextStyle(color: Colors.grey[800], height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
