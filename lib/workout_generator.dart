import 'models/exercise.dart';

class DailyWorkout {
  final int day;
  final List<Exercise> exercises;

  DailyWorkout({required this.day, required this.exercises});
}

class WorkoutGenerator {
  // база упражнений (15 штук)
  static final List<Exercise> _allExercises = [
    Exercise(name: "Приседания", reps: 15, imageUrl: "assets/gif/squats.gif"),
    Exercise(name: "Отжимания", reps: 12, imageUrl: "assets/gif/push_ups.gif"),
    Exercise(
      name: "Подтягивания",
      reps: 8,
      imageUrl: "assets/gifs/pull_ups.gif",
    ),
    Exercise(name: "Выпады", reps: 12, imageUrl: "assets/images/lunge.gif"),
    Exercise(
      name: "Планка с подъёмом ног",
      isTimed: true,
      duration: 30,
      imageUrl: "assets/gifs/plank_.gif",
    ),
    Exercise(
      name: "Приседания с весом",
      reps: 10,
      imageUrl: "assets/gifs/weighted_squats.gif",
    ),
    Exercise(
      name: "Скручивания",
      reps: 10,
      imageUrl: "assets/gifs/twisting.gif",
    ),
    Exercise(
      name: "Прыжки на месте",
      reps: 30,
      imageUrl: "assets/gifs/jumping_on_the_spot.gif",
    ),
    Exercise(
      name: "Бег на месте",
      isTimed: true,
      duration: 45,
      imageUrl: "assets/gifs/running_on_the_spot.gif",
    ),
    Exercise(
      name: "Альпинист",
      reps: 20,
      imageUrl: "assets/gifs/mountaineer.gif",
    ),
    Exercise(
      name: "Планка",
      isTimed: true,
      duration: 40,
      imageUrl: "assets/images/plank.png",
    ),
    Exercise(
      name: "Разминка",
      isTimed: true,
      duration: 60,
      imageUrl: "assets/images/warmup.gif",
    ),
    Exercise(
      name: "Растяжка ног",
      isTimed: true,
      duration: 40,
      imageUrl: "assets/images/leg_stretching.png",
    ),
    Exercise(
      name: "Растяжка спины",
      isTimed: true,
      duration: 40,
      imageUrl: "assets/images/stretch_back.gif",
    ),
    Exercise(
      name: "Йога: Собака мордой вниз",
      isTimed: true,
      duration: 45,
      imageUrl: "assets/images/yoga.gif",
    ),
  ];

  /// Генерация плана на N дней
  static List<DailyWorkout> generatePlan({
    required String
    goal, // "Сбросить вес", "Набрать мышечную массу", "Поддерживать форму"
    required int age,
    required double weight,
    int days = 30,
  }) {
    List<DailyWorkout> plan = [];

    for (int i = 1; i <= days; i++) {
      List<Exercise> dailyExercises = [];

      // базовая логика распределения
      if (goal == "Сбросить вес") {
        // больше кардио
        dailyExercises = _pickExercises(["cardio", "strength"], 5, i);
      } else if (goal == "Набрать мышечную массу") {
        // упор на силовые
        dailyExercises = _pickExercises(["strength"], 5, i);
      } else {
        // баланс
        dailyExercises = _pickExercises(
          ["strength", "cardio", "mobility"],
          5,
          i,
        );
      }

      // корректировка по возрасту
      if (age > 45) {
        dailyExercises = dailyExercises.map((ex) {
          if (!ex.isTimed) {
            return Exercise(
              name: ex.name,
              reps: (ex.reps * 0.8).toInt().clamp(5, ex.reps),
              imageUrl: ex.imageUrl,
            );
          } else {
            return Exercise(
              name: ex.name,
              isTimed: true,
              duration: (ex.duration * 0.8).toInt().clamp(15, ex.duration),
              imageUrl: ex.imageUrl,
            );
          }
        }).toList();
      }

      plan.add(DailyWorkout(day: i, exercises: dailyExercises));
    }

    return plan;
  }

  /// Вспомогательная функция для выбора упражнений
  static List<Exercise> _pickExercises(
    List<String> categories,
    int count,
    int seed,
  ) {
    // пока у нас нет категорий внутри Exercise, просто берём разные упражнения по кругу
    final start = seed % _allExercises.length;
    return List.generate(
      count,
      (i) => _allExercises[(start + i) % _allExercises.length],
    );
  }
}
