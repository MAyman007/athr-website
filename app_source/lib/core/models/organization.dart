import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final List<String> domains;
  final List<String> ipRanges;
  final List<String> keywords;
  final String createdBy; // User UID
  final DateTime? createdAt;

  Organization({
    required this.id,
    required this.name,
    required this.domains,
    required this.ipRanges,
    required this.keywords,
    required this.createdBy,
    this.createdAt,
  });

  // Note: fromMap is not needed yet, but is good practice for when you read data.
  factory Organization.fromMap(String id, Map<String, dynamic> map) {
    return Organization(
      id: id,
      name: map['name'] ?? '',
      domains: List<String>.from(map['domains'] ?? []),
      ipRanges: List<String>.from(map['ipRanges'] ?? []),
      keywords: List<String>.from(map['keywords'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'domains': domains,
      'ipRanges': ipRanges,
      'keywords': keywords,
      'createdBy': createdBy,
      // Use FieldValue for server-side timestamp on creation
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
