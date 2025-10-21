import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../workout_generator.dart';
import 'workout_executor_page.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<DailyWorkout> _plan = [];
  int _activeDay = 1; // 1-based
  final int _planDays = 30;

  @override
  void initState() {
    super.initState();
    _loadProfileAndPlan();
  }

  Future<void> _loadProfileAndPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      setState(() => _loading = false);
      return;
    }

    final data = doc.data()!;
    DateTime startDate;

    if (data['startDate'] == null) {
      startDate = DateTime.now();
      await docRef.set({'startDate': startDate}, SetOptions(merge: true));
    } else {
      final sd = data['startDate'];
      if (sd is Timestamp) {
        startDate = sd.toDate();
      } else if (sd is DateTime) {
        startDate = sd;
      } else {
        startDate = DateTime.now();
      }
    }

    final int dayFromStart = DateTime.now().difference(startDate).inDays + 1;
    final int lastCompleted = (data['lastCompletedDay'] ?? 0) as int;

    int active;
    if (lastCompleted + 1 > dayFromStart) {
      active = min(lastCompleted + 1, _planDays);
    } else {
      active = min(dayFromStart, _planDays);
    }

    final plan = WorkoutGenerator.generatePlan(
      goal: data['goal'] ?? 'Поддерживать форму',
      age: data['age'] ?? 25,
      weight: (data['weight'] ?? 70).toDouble(),
      days: _planDays,
    );

    setState(() {
      _profile = data;
      _plan = plan;
      _activeDay = active;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text("Профиль не найден")));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Мои тренировки 💪",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildStartButton(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB6E3FF), Color(0xFFFFD6E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 100, bottom: 120),
          itemCount: _plan.length,
          itemBuilder: (context, index) {
            final dayWorkout = _plan[index];
            final isActive = (dayWorkout.day == _activeDay);
            final isCompleted = dayWorkout.day < _activeDay;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : isCompleted
                      ? Colors.grey.shade100
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  initiallyExpanded: isActive,
                  title: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.fitness_center,
                        color: isActive
                            ? const Color(0xFF7BC8F8)
                            : isCompleted
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "День ${dayWorkout.day}" +
                              (isActive ? '  (сегодня)' : ''),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? const Color(0xFF2B2B2B)
                                : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    ...dayWorkout.exercises.map(
                      (ex) => ListTile(
                        title: Text(ex.name),
                        subtitle: ex.isTimed
                            ? Text("${ex.duration} сек.")
                            : Text("${ex.reps} повторений"),
                        leading: const Icon(
                          Icons.accessibility_new,
                          color: Color(0xFF7BC8F8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7BC8F8), Color(0xFFB6E3FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutExecutorPage(
                                    plan: _plan,
                                    startDayIndex: index,
                                  ),
                                ),
                              ).then((_) => _loadProfileAndPlan());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Выполнить день',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
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
          onPressed: () {
            final startIndex = _activeDay - 1;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    WorkoutExecutorPage(plan: _plan, startDayIndex: startIndex),
              ),
            ).then((_) => _loadProfileAndPlan());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Начать сегодня',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
