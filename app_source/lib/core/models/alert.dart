/// Represents a single, specific security finding.
class Alert {
  final String id;
  final String type;
  final String description;
  final String source;
  final DateTime detectedAt;
  final Map<String, dynamic> rawData;

  Alert({
    required this.id,
    required this.type,
    required this.description,
    required this.source,
    required this.detectedAt,
    required this.rawData,
  });

  /// Creates an [Alert] from a JSON object.
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      source: json['source'] as String,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      rawData: json['rawData'] as Map<String, dynamic>,
    );
  }
}
