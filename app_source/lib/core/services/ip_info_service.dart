import 'dart:convert';
import 'package:athr/core/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class IpInfoService {
  Future<Map<String, dynamic>> fetchAccessDecision() async {
    try {
      // Use the compile-time safe environment variables from Env
      final response = await http.get(
        Uri.parse('${Env.ipCheckBaseUrl}/check-ip'),
        headers: {'x-api-key': Env.ipCheckApiKey},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // If the API returns an error, we grant access as a failsafe,
        // mimicking the backend's logic for when it can't reach ipinfo.io.
        debugPrint('Failed to check IP. Status code: ${response.statusCode}');
        return {
          'access_granted': true,
          'reason': 'API check failed, granting access as a failsafe.',
        };
      }
    } catch (e) {
      // Handle network errors (e.g., no internet, DNS issues).
      debugPrint('Error fetching IP access decision: $e');
      return {
        'access_granted': true,
        'reason':
            'Network error during API check, granting access as a failsafe.',
      };
    }
  }
}
