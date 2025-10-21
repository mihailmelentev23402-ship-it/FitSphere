import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../services/achievement_service.dart';

class WorkoutExecutorPage extends StatefulWidget {
  final List<dynamic> plan;
  final int startDayIndex;

  const WorkoutExecutorPage({
    super.key,
    required this.plan,
    required this.startDayIndex,
  });

  @override
  State<WorkoutExecutorPage> createState() => _WorkoutExecutorPageState();
}

class _WorkoutExecutorPageState extends State<WorkoutExecutorPage> {
  int _currentExerciseIndex = 0;
  late int _dayNumber;
  bool _completed = false;

  Timer? _timer;
  int _timeLeft = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _dayNumber = widget.startDayIndex + 1;
    _initTimerIfNeeded();
  }

  void _initTimerIfNeeded() {
    final current =
        widget.plan[_dayNumber - 1].exercises[_currentExerciseIndex]
            as Exercise;
    if (current.isTimed) {
      setState(() {
        _timeLeft = current.duration;
        _isRunning = false;
      });
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        _onNext();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onNext() {
    _timer?.cancel();
    if (_currentExerciseIndex <
        widget.plan[_dayNumber - 1].exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _initTimerIfNeeded();
      });
    } else {
      _onDayCompleted();
    }
  }

  Future<void> _onDayCompleted() async {
    setState(() => _completed = true);
    await _saveCompletion(_dayNumber);
    await AchievementService.checkAndUnlockAchievements(
      completedDays: _dayNumber,
      currentStreak: await _calculateStreak(),
      context: context,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тренировка завершена! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveCompletion(int day) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userRef.update({
      'lastCompletedDay': day,
      'lastWorkoutDate': FieldValue.serverTimestamp(),
    });

    await userRef.collection('workouts').add({
      'day': day,
      'date': FieldValue.serverTimestamp(),
    });
  }

  Future<int> _calculateStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .orderBy('date', descending: true);
    final docs = await ref.get();

    int streak = 0;
    DateTime? lastDate;
    for (final d in docs.docs) {
      final date = (d['date'] as Timestamp).toDate();
      if (lastDate == null || lastDate.difference(date).inDays == 1) {
        streak++;
        lastDate = date;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.plan[_dayNumber - 1].exercises;
    final current = exercises[_currentExerciseIndex] as Exercise;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'День $_dayNumber',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB6E3FF), Color(0xFFFFD6E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _completed
              ? const Center(
                  child: Text(
                    'Тренировка завершена! 🎉',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Название упражнения ---
                    Text(
                      current.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2B2B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    // --- Фото упражнения ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          current.imageUrl,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- Время или повторения ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: current.isTimed
                          ? Column(
                              children: [
                                Text(
                                  'Оставшееся время: $_timeLeft сек',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3A3A3A),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _startTimer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7BC8F8),
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Text(
                                    _isRunning
                                        ? 'Таймер идёт...'
                                        : 'Начать таймер',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Повторений: ${current.reps}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF3A3A3A),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(height: 40),

                    // --- Кнопка Следующее упражнение / Завершить ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7BC8F8), Color(0xFFB6E3FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentExerciseIndex == exercises.length - 1
                                ? 'Завершить тренировку'
                                : 'Следующее упражнение',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
