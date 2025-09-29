/// Represents a log entry associated with a security incident.
class Log {
  final int? entityId;
  final String? machineIp;
  final String? machineUsername;
  final String machineName; // Assuming machine name is essential
  final String? machineCountry;
  final String? machineLocations;
  final String? machineHwid;
  final String? malwarePath;
  final DateTime? malwareInstallDate;
  final List<String> domainsLeaked;
  final int? leakedCookies;
  final int? leakedAutofills;

  Log({
    this.entityId,
    this.machineIp,
    this.machineUsername,
    required this.machineName,
    this.machineCountry,
    this.machineLocations,
    this.machineHwid,
    this.malwarePath,
    this.malwareInstallDate,
    required this.domainsLeaked,
    this.leakedCookies,
    this.leakedAutofills,
  });

  /// Creates a [Log] from a JSON object.
  /// This factory is designed to be robust against missing or null data from the API.
  factory Log.fromJson(Map<String, dynamic> json) {
    final domains = (json['Domains_Leaked'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    return Log(
      entityId: json['entity_id'] as int?,
      machineIp: json['machine_ip']?.toString(),
      machineUsername: json['machine_username']?.toString(),
      machineName: json['machine_name']?.toString() ?? 'Unknown Machine',
      machineCountry: json['machine_country']?.toString(),
      machineLocations: json['machine_locations']?.toString(),
      machineHwid: json['machine_HWID']?.toString(),
      malwarePath: json['malware_path']?.toString(),
      malwareInstallDate: json['malware_installDate'] == null
          ? null
          : DateTime.tryParse(json['malware_installDate'] as String),
      domainsLeaked: domains ?? [],
      leakedCookies: json['Leaked_cookies'] as int?,
      leakedAutofills: json['Leaked_Autofills'] as int?,
    );
  }
}
