class Exercise {
  final String name;
  final bool isTimed;
  final int reps; // если упражнение по повторениям
  final int duration; // если упражнение по времени
  final String imageUrl;

  Exercise({
    required this.name,
    this.isTimed = false,
    this.reps = 0,
    this.duration = 0,
    this.imageUrl = "",
  });
}
