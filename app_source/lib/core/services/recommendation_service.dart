import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:athr/core/models/incident.dart';
import 'package:athr/core/models/recommendation.dart';

class RecommendationService {
  // A private cache to avoid reading the file every time
  List<Recommendation>? _cachedRecommendations;

  Future<List<Recommendation>> _loadRecommendations() async {
    if (_cachedRecommendations != null) {
      return _cachedRecommendations!;
    }
    // Load the JSON string from the asset file
    final jsonString = await rootBundle.loadString(
      'assets/recommendations.json',
    );
    // Decode the JSON string into a list of dynamic maps
    final List<dynamic> jsonList = json.decode(jsonString);
    // Parse the list of maps into a list of Recommendation objects
    _cachedRecommendations = jsonList
        .map((json) => Recommendation.fromJson(json))
        .toList();
    return _cachedRecommendations!;
  }

  /// This is your client-side "rules engine" for the demo
  Future<List<Recommendation>> getRecommendationsForIncident(
    Incident incident,
    String metricId,
  ) async {
    final allRecs = await _loadRecommendations();
    final relevantRecs = <Recommendation>{}; // Use a Set to avoid duplicates
    final incidentSeverity = incident.severity.name;

    switch (metricId) {
      case 'total-incidents':
      case 'high-severity':
        relevantRecs.addAll(
          allRecs.where(
            (rec) =>
                rec.scope == 'general' &&
                rec.appliesTo == 'all' &&
                rec.severity == incidentSeverity,
          ),
        );
        break;
      case 'leaked-credentials':
        relevantRecs.addAll(
          allRecs.where(
            (rec) =>
                rec.scope == 'ulp' &&
                rec.appliesTo == 'ulp' &&
                rec.severity == incidentSeverity,
          ),
        );
        break;
      case 'compromised-machines':
        relevantRecs.addAll(
          allRecs.where(
            (rec) => rec.scope == 'logs' && rec.severity == incidentSeverity,
          ),
        );
        break;
      default:
        // Fallback to general recommendations if metricId is unknown
        relevantRecs.addAll(allRecs.where((rec) => rec.scope == 'general'));
        break;
    }

    // 4. Sort the final list by severity
    final sortedList = relevantRecs.toList();
    final severityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
    sortedList.sort(
      (a, b) =>
          severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!),
    );

    return sortedList;
  }
}
