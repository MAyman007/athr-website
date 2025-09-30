import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Add this import

import '../models/incident.dart';
import 'firebase_service.dart';
import '../locator.dart';

/// A service responsible for fetching incident data from the API.
class IncidentService {
  // Depend on the FirebaseService via the locator
  final FirebaseService _firebaseService = locator<FirebaseService>();
  final String _apiEndpoint =
      'https://athr-dashboard.mohamedayman.org/search/domains';

  /// Fetches a list of incidents for the currently authenticated user's organization.
  ///
  /// This method performs the following steps:
  /// 1. Gets the current authenticated user.
  /// 2. Fetches the user's `org_id` from Firestore.
  /// 3. Fetches the organization's domains using the `org_id`.
  /// 4. Makes a POST request to the API with the domains.
  /// 5. Parses the JSON response into a list of [Incident] objects.
  ///
  /// Throws an [Exception] if any step fails.
  Future<List<Incident>> fetchIncidents({
    int page = 1,
    int limit = 20,
    String? metricId,
  }) async {
    try {
      // 1. Get the current authenticated user
      final User? user = _firebaseService.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in.');
      }

      // 2. Fetch user document to get org_id
      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('User document not found in Firestore.');
      }
      final String? orgId = userDoc.data()!['orgId'];
      if (orgId == null) {
        throw Exception('Organization ID not found for the user.');
      }

      // 3. Fetch organization document to get domains
      final orgDoc = await _firebaseService.firestore
          .collection('organizations')
          .doc(orgId)
          .get();
      if (!orgDoc.exists || orgDoc.data() == null) {
        throw Exception('Organization document not found in Firestore.');
      }
      final List<String> domains = List<String>.from(
        orgDoc.data()!['domains'] ?? [],
      );
      if (domains.isEmpty) {
        // Return an empty list if there are no domains to search for.
        return [];
      }

      var url =
          '$_apiEndpoint?domains=${domains.join(',')}&page=$page&limit=$limit';

      if (metricId != null && metricId != 'total-incidents') {
        url += '&metricId=$metricId';
      }
      debugPrint('API Endpoint: $url');

      // 4. Make a GET request with domains as a comma-separated query parameter.
      final uri = Uri.parse(url);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        // 5. Parse the JSON response
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((data) => Incident.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch incidents from API: ${response.statusCode} ${response.body}',
        );
      }
    } on UnsupportedError {
      throw Exception('Failed to parse API endpoint: $_apiEndpoint');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      // Rethrow any other exceptions
      rethrow;
    }
  }
}
