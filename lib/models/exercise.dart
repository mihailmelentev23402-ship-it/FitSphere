class Exercise {
  final String name;
  final bool isTimed;
  final int reps; // если упражнение по повторениям
  final int duration; // если упражнение по времени (сек)
  final String imageUrl;

  Exercise({
    required this.name,
    this.isTimed = false,
    this.reps = 0,
    this.duration = 0,
    this.imageUrl = "",
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'isTimed': isTimed,
    'reps': reps,
    'duration': duration,
    'imageUrl': imageUrl,
  };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    name: j['name'] ?? '',
    isTimed: j['isTimed'] ?? false,
    reps: (j['reps'] ?? 0) as int,
    duration: (j['duration'] ?? 0) as int,
    imageUrl: j['imageUrl'] ?? '',
  );
}
