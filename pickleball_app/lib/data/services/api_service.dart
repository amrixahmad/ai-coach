import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_config.dart';
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

class SavedAnalysis {
  final String id;
  final String? videoUrl;
  final String? createdAt;
  final AnalysisResult analysisResult;

  SavedAnalysis({
    required this.id,
    this.videoUrl,
    this.createdAt,
    required this.analysisResult,
  });

  factory SavedAnalysis.fromJson(Map<String, dynamic> json) {
    final geminiData = json['gemini_analysis'] as Map<String, dynamic>? ?? {};
    final trackingRaw = json['tracking_data'] as List<dynamic>? ?? [];
    
    final strokeAnalysis = StrokeAnalysis.fromJson(geminiData);
    final trackingList = trackingRaw
        .map((item) => TrackingFrame.fromJson(item as Map<String, dynamic>))
        .toList();

    final rawVideoUrl = json['video_url'] as String?;
    final resolvedVideoUrl = ApiConfig.resolveUrl(rawVideoUrl);

    return SavedAnalysis(
      id: json['id'] ?? '',
      videoUrl: resolvedVideoUrl,
      createdAt: json['created_at'] as String?,
      analysisResult: AnalysisResult(
        analysis: strokeAnalysis,
        tracking: trackingList,
        videoUrl: resolvedVideoUrl,
      ),
    );
  }
}

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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
      final rawVideoUrl = metadata?['video_url'] as String?;
      final resolvedVideoUrl = ApiConfig.resolveUrl(rawVideoUrl);

      return AnalysisResult(
        analysis: strokeAnalysis,
        tracking: trackingList,
        videoUrl: resolvedVideoUrl,
      );
    } else {
      throw Exception('Failed to process video: HTTP ${response.statusCode}');
    }
  }

  Future<List<SavedAnalysis>> getAnalyses({String? authToken}) async {
    final uri = Uri.parse('$baseUrl/analyses');
    final headers = <String, String>{};
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final list = json.decode(response.body) as List<dynamic>;
      return list.map((item) => SavedAnalysis.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch analyses: HTTP ${response.statusCode}');
    }
  }

  Future<void> deleteAnalysis(String id, {String? authToken}) async {
    final uri = Uri.parse('$baseUrl/analyses/$id');
    final headers = <String, String>{};
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete analysis: HTTP ${response.statusCode}');
    }
  }
}

