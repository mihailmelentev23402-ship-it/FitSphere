import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementService {
  /// Проверяет и разблокирует достижения
  static Future<void> checkAndUnlockAchievements({
    required int completedDays,
    required int currentStreak,
    required BuildContext context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final achievementsRef = userRef.collection('achievements');

    // 🚫 Если пользователь ещё ничего не выполнил — выходим
    if (completedDays <= 0) return;

    // Загружаем уже разблокированные достижения
    final snapshot = await achievementsRef.get();
    final unlocked = snapshot.docs.map((d) => d.id).toSet();

    // 🏅 Список всех достижений с условиями
    final achievements = [
      {
        'id': 'first_workout',
        'title': 'Первая тренировка!',
        'description': 'Ты начал свой путь 💪',
        'condition': completedDays >= 1,
      },
      {
        'id': '15_workouts',
        'title': '15 тренировок!',
        'description': 'Ты уже почти на полпути к цели 🔥',
        'condition': completedDays >= 15,
      },
      {
        'id': '5_day_streak',
        'title': 'Серия из 5 дней!',
        'description': 'Настоящая дисциплина 💥',
        'condition': currentStreak >= 5,
      },
      {
        'id': '30_workouts',
        'title': '30 тренировок!',
        'description': 'Месяц продуктивности! 💪',
        'condition': completedDays >= 30,
      },
      {
        'id': '10_day_streak',
        'title': '10 дней подряд!',
        'description': 'Ты на пути к совершенству 🌟',
        'condition': currentStreak >= 10,
      },
    ];

    for (final a in achievements) {
      if (a['condition'] == true && !unlocked.contains(a['id'])) {
        await achievementsRef.doc(a['id'] as String).set({
          'title': a['title'],
          'description': a['description'],
          'unlockedAt': FieldValue.serverTimestamp(),
        });

        // 🎉 Показываем красивое уведомление при разблокировке
        _showAchievementPopup(
          context,
          title: a['title'] as String,
          description: a['description'] as String,
        );
      }
    }
  }

  /// 🎉 Всплывающее уведомление при получении достижения
  static void _showAchievementPopup(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Круто!'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
