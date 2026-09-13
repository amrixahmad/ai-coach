class TrackingFrame {
  final int frame;
  final double timestamp;
  final double headX;
  final double headY;
  final double elbowAngle;
  final double kneeAngle;
  final double wristX;
  final double wristY;

  TrackingFrame({
    required this.frame,
    required this.timestamp,
    required this.headX,
    required this.headY,
    required this.elbowAngle,
    required this.kneeAngle,
    required this.wristX,
    required this.wristY,
  });

  factory TrackingFrame.fromJson(Map<String, dynamic> json) {
    return TrackingFrame(
      frame: json['frame'] ?? 0,
      timestamp: (json['timestamp'] ?? 0.0).toDouble(),
      headX: (json['head_x'] ?? 0.5).toDouble(),
      headY: (json['head_y'] ?? 0.5).toDouble(),
      elbowAngle: (json['elbow_angle'] ?? 180.0).toDouble(),
      kneeAngle: (json['knee_angle'] ?? 180.0).toDouble(),
      wristX: (json['wrist_x'] ?? 0.5).toDouble(),
      wristY: (json['wrist_y'] ?? 0.5).toDouble(),
    );
  }
}
