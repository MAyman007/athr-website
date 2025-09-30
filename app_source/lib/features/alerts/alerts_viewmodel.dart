import 'package:flutter/foundation.dart';
import 'package:athr/core/locator.dart';
import 'package:athr/core/models/incident.dart';
import 'package:athr/core/services/incident_service.dart';

/// Manages the state and business logic for the Alerts page.
class AlertsViewModel extends ChangeNotifier {
  final IncidentService _incidentService = locator<IncidentService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Incident> _allIncidents = [];
  final Set<int> _readIncidentIds = {}; // Using artifactId as the ID

  /// A list of incidents that have not been marked as read.
  List<Incident> get unreadAlerts => _allIncidents
      .where((incident) => !_readIncidentIds.contains(incident.artifactId))
      .toList();

  /// Fetches all incidents from the service.
  Future<void> loadAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // For a real-world alert feed, you might only fetch recent or unread incidents.
      // Here, we fetch all and manage the read state locally.
      _allIncidents = await _incidentService.fetchIncidents(limit: 1000);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a single alert as read.
  void markAsRead(int artifactId) {
    if (_readIncidentIds.add(artifactId)) {
      notifyListeners();
    }
  }
}
