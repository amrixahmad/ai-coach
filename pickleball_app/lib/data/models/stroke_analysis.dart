class StrokeItem {
  final String timestampOfOutcome;
  final String result; // 'good', 'missed', 'illegal_serve'
  final String shotType; // 'Dink', 'Serve', 'Drive', etc.
  final String feedback;
  final int totalShotsMadeSoFar;
  final int totalShotsMissedSoFar;

  StrokeItem({
    required this.timestampOfOutcome,
    required this.result,
    required this.shotType,
    required this.feedback,
    required this.totalShotsMadeSoFar,
    required this.totalShotsMissedSoFar,
  });

  factory StrokeItem.fromJson(Map<String, dynamic> json) {
    return StrokeItem(
      timestampOfOutcome: json['timestamp_of_outcome'] ?? '0:00.0',
      result: json['result'] ?? 'good',
      shotType: json['shot_type'] ?? 'Stroke',
      feedback: json['feedback'] ?? '',
      totalShotsMadeSoFar: json['total_shots_made_so_far'] ?? 0,
      totalShotsMissedSoFar: json['total_shots_missed_so_far'] ?? 0,
    );
  }
}

class StrokeAnalysis {
  final List<StrokeItem> strokes;

  StrokeAnalysis({required this.strokes});

  factory StrokeAnalysis.fromJson(Map<String, dynamic> json) {
    final rawShots = json['shots'] as List<dynamic>? ?? [];
    final strokes = rawShots
        .map((item) => StrokeItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return StrokeAnalysis(strokes: strokes);
  }
}
