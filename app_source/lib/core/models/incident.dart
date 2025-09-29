import 'package:flutter/material.dart';
import 'log.dart'; // Import the new Log model

/// Enum for the severity of an incident.
enum IncidentSeverity { critical, high, medium, low, informational, unknown }

/// Extension to add a helper method to [IncidentSeverity] for UI elements.
extension IncidentSeverityColor on IncidentSeverity {
  Color get color {
    switch (this) {
      case IncidentSeverity.critical:
        return Colors.red.shade700;
      case IncidentSeverity.high:
        return Colors.orange.shade700;
      case IncidentSeverity.medium:
        return Colors.yellow.shade700;
      case IncidentSeverity.low:
        return Colors.blue.shade700;
      case IncidentSeverity.informational:
        return Colors.grey.shade700;
      case IncidentSeverity.unknown:
        return Colors.grey.shade500;
    }
  }
}

/// Represents a security incident, which is a collection of related alerts.
class Incident {
  final int artifactId;
  final String source;
  final String? sourcePath;
  final String? originalFilename;
  final IncidentSeverity severity;
  final String? category;
  final String? mimeType;
  final int sizeBytes;
  final String? hashSha256;
  final DateTime? createdAt;
  final DateTime? postedAt;
  final String? storagePath;
  final List<String> emails;
  final List<Log> logs;

  Incident({
    required this.artifactId,
    required this.source,
    required this.sourcePath,
    required this.originalFilename,
    required this.severity,
    this.category,
    required this.mimeType,
    required this.sizeBytes,
    required this.hashSha256,
    this.createdAt,
    this.postedAt,
    required this.storagePath,
    required this.emails,
    required this.logs,
  });

  /// Creates an [Incident] from a JSON object.
  /// This factory is designed to be robust against missing or null data from the API.
  factory Incident.fromJson(Map<String, dynamic> json) {
    // Safely parse lists, ensuring they are never null.
    final List<String> emailsList =
        (json['emails'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];

    final List<Log> logsList =
        (json['logs'] as List<dynamic>?)
            ?.map((logJson) => Log.fromJson(logJson as Map<String, dynamic>))
            .toList() ??
        [];

    return Incident(
      artifactId: json['artifact_id'] as int,
      source: json['source']?.toString() ?? 'Unknown Source',
      sourcePath: json['source_path']?.toString(),
      originalFilename: json['original_filename']?.toString(),
      severity: severityFromString(json['severity']?.toString()),
      category: json['category']?.toString(),
      mimeType: json['mime_type']?.toString(),
      sizeBytes: json['size_bytes'] as int? ?? 0,
      hashSha256: json['hash_sha256']?.toString(),
      createdAt: json['collected_at'] != null
          ? DateTime.tryParse(json['collected_at'] as String)
          : null,
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'] as String)
          : null,
      storagePath: json['storage_path']?.toString(),
      emails: emailsList,
      logs: logsList,
    );
  }

  /// Parses a string to an [IncidentSeverity] enum.
  static IncidentSeverity severityFromString(String? severity) {
    // Use a case-insensitive lookup for robustness.
    for (final value in IncidentSeverity.values) {
      if (value.name.toLowerCase() == severity?.toLowerCase()) {
        return value;
      }
    }
    return IncidentSeverity.unknown;
  }
}
