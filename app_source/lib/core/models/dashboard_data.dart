import 'incident.dart';

/// Represents the data structure for the main dashboard.
class DashboardData {
  final Map<IncidentSeverity, int> incidentCountBySeverity;
  final List<Incident> recentHighPriorityIncidents;
  final int totalOpenIncidents;
  final int newAlertsToday;

  DashboardData({
    required this.incidentCountBySeverity,
    required this.recentHighPriorityIncidents,
    required this.totalOpenIncidents,
    required this.newAlertsToday,
  });

  /// Creates [DashboardData] from a JSON object.
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final Map<String, int> counts = Map<String, int>.from(
      json['incidentCountBySeverity'] as Map,
    );

    final severityMap = counts.map(
      (key, value) => MapEntry(Incident.severityFromString(key), value),
    );

    return DashboardData(
      incidentCountBySeverity: severityMap,
      recentHighPriorityIncidents: (json['recentHighPriorityIncidents'] as List)
          .map((i) => Incident.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalOpenIncidents: json['totalOpenIncidents'] as int,
      newAlertsToday: json['newAlertsToday'] as int,
    );
  }
}
