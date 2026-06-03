class FestivalSection {
  final String? region;
  final String title;
  final String description;
  final List<String> observances;

  const FestivalSection({
    this.region,
    required this.title,
    required this.description,
    required this.observances,
  });

  factory FestivalSection.fromJson(Map<String, dynamic> json) => FestivalSection(
        region: json['region'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        observances: (json['observances'] as List<dynamic>).cast<String>(),
      );
}

class FestivalContent {
  final String? subtitle;
  final String? intro;
  final String description;
  final List<String> observances;
  final List<FestivalSection> sections;

  const FestivalContent({
    this.subtitle,
    this.intro,
    this.description = '',
    this.observances = const [],
    this.sections = const [],
  });

  bool get isCombined => sections.isNotEmpty;

  factory FestivalContent.fromJson(Map<String, dynamic> json) => FestivalContent(
        subtitle: json['subtitle'] as String?,
        intro: json['intro'] as String?,
        description: json['description'] as String? ?? '',
        observances: (json['observances'] as List<dynamic>? ?? []).cast<String>(),
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((s) => FestivalSection.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
