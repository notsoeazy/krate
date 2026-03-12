class Subtitle {
  final int? id;
  final int episodeId;
  final String path;
  final String name;

  const Subtitle({
    this.id,
    required this.episodeId,
    required this.path,
    required this.name,
  });

  Map<String, dynamic> toMap() => {
    'episodeId': episodeId,
    'path': path,
    'name': name,
  };

  factory Subtitle.fromMap(Map<String, dynamic> map) {
    return Subtitle(
      id: map['id'] as int?,
      episodeId: map['episodeId'] as int,
      path: map['path'] as String,
      name: map['name'] as String,
    );
  }

  Subtitle copyWith({
    int? id,
    int? episodeId,
    String? path,
    String? name,
  }) {
    return Subtitle(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      path: path ?? this.path,
      name: name ?? this.name,
    );
  }
}
