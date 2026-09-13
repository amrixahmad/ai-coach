import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/tracking_frame.dart';
import '../../../data/services/api_service.dart';
import 'pose_painter.dart';

class ResultsView extends StatefulWidget {
  final File videoFile;
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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
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

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strokes = widget.analysisResult.analysis.strokes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroke Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Video Player with Synchronized Pose Overlay
          if (_controller.value.isInitialized)
            AspectRatio(
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
            )
          else
            const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator()),
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

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          Text(stroke.timestampOfOutcome, style: TextStyle(color: Colors.grey[600])),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(stroke.shotType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(stroke.feedback, style: TextStyle(color: Colors.grey[800], height: 1.4)),
                                    ],
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
