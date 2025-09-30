class Recommendation {
  final int id;
  final String scope;
  final String appliesTo;
  final String title;
  final String severity;
  final String summary;
  final List<String> steps;
  final List<String> tags;
  final String? notes;

  Recommendation({
    required this.id,
    required this.scope,
    required this.appliesTo,
    required this.title,
    required this.severity,
    required this.summary,
    required this.steps,
    required this.tags,
    this.notes,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      scope: json['scope'],
      appliesTo: json['applies_to'],
      title: json['title'],
      severity: json['severity'],
      summary: json['summary'],
      // Split the semicolon-separated string into a list
      steps: (json['steps'] as String).split(';'),
      // Split the comma-separated string into a list
      tags: (json['tags'] as String).split(','),
      notes: json['notes'],
    );
  }
}
