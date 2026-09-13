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
  double _playbackSpeed = 1.0;

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

  void _changeSpeed(double speed) {
    if (!_controller.value.isInitialized) return;
    _controller.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
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

  String _getDrillRecommendation(String shotType) {
    final type = shotType.toLowerCase();
    if (type.contains('dink')) {
      return '🏓 Wall Dink Drill: Practice 5 mins x 3 sets. Place non-paddle hand on knee to lock low center of gravity and keep paddle face at 90°.';
    } else if (type.contains('serve')) {
      return '🎾 Low-to-High Serve Drill: Start paddle below waist level with wrist locked. Perform 20 shadow swings aiming for a smooth underhand arc.';
    } else if (type.contains('drop') || type.contains('third')) {
      return '🎯 Soft Touch Drop Drill: Have a partner feed balls from kitchen line. Focus on catching ball on paddle strings gently without swinging back.';
    }
    return '⚡ Compact Stroke Drill: Perform 30 reps against a wall, focusing on minimal backswing and solid forward follow-through.';
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
    final maxHeight = MediaQuery.of(context).size.height * 0.42;

    final kneeAngle = _currentTrackingFrame?.kneeAngle ?? 0.0;
    final elbowAngle = _currentTrackingFrame?.elbowAngle ?? 0.0;
    final isGoodKnee = kneeAngle > 0 && kneeAngle < 135;
    final isGoodElbow = elbowAngle > 0 && elbowAngle < 155;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroke Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Video Player Container with Glassmorphism HUD Overlays
          if (_controller.value.isInitialized)
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: maxHeight),
              color: Colors.black,
              child: Stack(
                children: [
                  Center(
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

                  // HUD Status Chips (Top)
                  if (_currentTrackingFrame != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isGoodKnee ? Colors.green.withOpacity(0.85) : Colors.red.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Row(
                              children: [
                                Icon(isGoodKnee ? Icons.check_circle : Icons.warning_amber_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Knee: ${kneeAngle.round()}° ${isGoodKnee ? "(Optimal)" : "(Too Tall)"}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isGoodElbow ? Colors.teal.withOpacity(0.85) : Colors.amber.shade900.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Row(
                              children: [
                                Icon(isGoodElbow ? Icons.check_circle : Icons.info_outline, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Elbow: ${elbowAngle.round()}° ${isGoodElbow ? "(Compact)" : "(Extended)"}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Slow-Mo Playback Speed Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed, color: Colors.tealAccent, size: 18),
                    SizedBox(width: 6),
                    Text('Playback Speed:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [0.25, 0.5, 1.0].map((speed) {
                    final isSelected = _playbackSpeed == speed;
                    return GestureDetector(
                      onTap: () => _changeSpeed(speed),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.tealAccent : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Stroke Breakdown List & Actionable Practice Drills
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stroke Breakdown & Coaching Drills',
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
                                margin: const EdgeInsets.only(bottom: 14),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
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
                                        const SizedBox(height: 10),
                                        Text(stroke.shotType, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(stroke.feedback, style: TextStyle(color: Colors.grey[800], height: 1.4)),

                                        // Pro Target Benchmark Badge
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.sports_score_rounded, size: 16, color: Colors.teal),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Pro Target: 110°–125° Knee Squat | 120°–145° Elbow',
                                                  style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Actionable Coaching Drill Recommendation
                                        if (!isGood) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.amber.shade200),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.fitness_center_rounded, size: 16, color: Colors.amber.shade900),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'HOW TO FIX THIS (PRACTICE DRILL)',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _getDrillRecommendation(stroke.shotType),
                                                  style: TextStyle(fontSize: 13, color: Colors.amber.shade900, height: 1.3),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
