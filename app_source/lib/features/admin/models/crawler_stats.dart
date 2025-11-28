class Leak {
  final String leakName;
  final String discovered;
  final String? country;
  final String sourceGroup;
  final String linkSource;

  Leak({
    required this.leakName,
    required this.discovered,
    this.country,
    required this.sourceGroup,
    required this.linkSource,
  });

  factory Leak.fromJson(Map<String, dynamic> json) {
    return Leak(
      leakName: json['leak_name'] ?? '',
      discovered: json['discovered'] ?? '',
      country: json['country'],
      sourceGroup: json['source_group'] ?? '',
      linkSource: json['link_source'] ?? '',
    );
  }
}
