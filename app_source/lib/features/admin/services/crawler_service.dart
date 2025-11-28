import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crawler_stats.dart';

class CrawlerService {
  Future<List<Leak>> getCrawlerStats() async {
    try {
      final response = await http.get(
        Uri.parse('https://athrph.mohamedayman.net/leaks'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Leak.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load leaks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load leaks: $e');
    }
  }
}
