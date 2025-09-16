class UserSettings {
  final String primaryNotificationEmail;
  final String secondaryNotificationEmail;
  final String alertFrequency;

  UserSettings({
    required this.primaryNotificationEmail,
    required this.secondaryNotificationEmail,
    required this.alertFrequency,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      primaryNotificationEmail: map['primaryNotificationEmail'] ?? '',
      secondaryNotificationEmail: map['secondaryNotificationEmail'] ?? '',
      alertFrequency: map['alertFrequency'] ?? 'Daily Digest',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryNotificationEmail': primaryNotificationEmail,
      'secondaryNotificationEmail': secondaryNotificationEmail,
      'alertFrequency': alertFrequency,
    };
  }
}

class AppUser {
  final String uid;
  final String orgId;
  final String email;
  final String fullName;
  final String role;
  final UserSettings settings;

  AppUser({
    required this.uid,
    required this.orgId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.settings,
  });

  // Note: fromMap is not needed yet, but is good practice for when you read data.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      orgId: map['orgId'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'user',
      settings: UserSettings.fromMap(map['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'email': email,
      'fullName': fullName,
      'role': role,
      'settings': settings.toMap(),
    };
  }
}
