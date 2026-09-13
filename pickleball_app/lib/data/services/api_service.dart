import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/stroke_analysis.dart';
import '../models/tracking_frame.dart';

class AnalysisResult {
  final StrokeAnalysis analysis;
  final List<TrackingFrame> tracking;
  final String? videoUrl;

  AnalysisResult({
    required this.analysis,
    required this.tracking,
    this.videoUrl,
  });
}

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://10.0.2.2:8000'}); // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web

  Future<AnalysisResult> processVideo(File videoFile, {String? authToken}) async {
    final uri = Uri.parse('$baseUrl/process-video');
    final request = http.MultipartRequest('POST', uri);

    if (authToken != null && authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }

    final multipartFile = await http.MultipartFile.fromPath('file', videoFile.path);
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      final strokeAnalysis = StrokeAnalysis.fromJson(data['analysis'] ?? {});
      final trackingList = (data['tracking'] as List<dynamic>? ?? [])
          .map((item) => TrackingFrame.fromJson(item as Map<String, dynamic>))
          .toList();

      final metadata = data['metadata'] as Map<String, dynamic>?;
      final videoUrl = metadata?['video_url'] as String?;

      return AnalysisResult(
        analysis: strokeAnalysis,
        tracking: trackingList,
        videoUrl: videoUrl,
      );
    } else {
      throw Exception('Failed to process video: HTTP ${response.statusCode}');
    }
  }
}
