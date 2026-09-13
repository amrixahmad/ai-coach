import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  ApiService({this.baseUrl = 'http://localhost:8000'});

  Future<AnalysisResult> processVideo(XFile videoFile, {String? authToken}) async {
    final uri = Uri.parse('$baseUrl/process-video');
    final request = http.MultipartRequest('POST', uri);

    if (authToken != null && authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }

    if (kIsWeb) {
      final bytes = await videoFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: videoFile.name.isNotEmpty ? videoFile.name : 'upload.mp4',
      );
      request.files.add(multipartFile);
    } else {
      final multipartFile = await http.MultipartFile.fromPath('file', videoFile.path);
      request.files.add(multipartFile);
    }

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
