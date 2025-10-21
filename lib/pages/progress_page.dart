import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  int _totalDays = 30;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _profile = doc.data();
        _loading = false;
      });

      // После загрузки данных делаем автопрокрутку
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScrollToActiveDay();
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _autoScrollToActiveDay() {
    final completedDays = _profile?['lastCompletedDay'] ?? 0;
    if (_scrollController.hasClients) {
      final target = (completedDays > 3 ? completedDays - 3 : 0) * 70.0;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text("Нет данных профиля")));
    }

    final completedDays = _profile!['lastCompletedDay'] ?? 0;
    final progress = (completedDays / _totalDays).clamp(0.0, 1.0);
    final remainingDays = _totalDays - completedDays;

    String message;
    if (progress == 0) {
      message = "Начни сегодня 💪";
    } else if (progress < 0.3) {
      message = "Хорошее начало, продолжай!";
    } else if (progress < 0.7) {
      message = "Отличный темп! Уже середина пути 🚀";
    } else if (progress < 1.0) {
      message = "Финиш близко 🔥";
    } else {
      message = "Ты завершил план! Поздравляем 🎉";
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Прогресс",
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB6E3FF), Color(0xFFFFD6E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(seconds: 2),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                final animatedPercent = (animatedValue * 100).toStringAsFixed(
                  0,
                );

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Прогресс-круг ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7BC8F8), Color(0xFFB6E3FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: animatedValue,
                            strokeWidth: 14,
                            backgroundColor: Colors.white.withOpacity(0.4),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7BC8F8),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Text(
                                "$animatedPercent%",
                                key: ValueKey(animatedPercent),
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B2B2B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "выполнено",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),

                    // --- Новый streak-график ---
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _totalDays,
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final isDone = day <= completedDays;
                          final isActive = day == completedDays + 1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: isActive ? 65 : 55,
                              height: isActive ? 65 : 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: isDone
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF7BC8F8),
                                          Color(0xFFB6E3FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : isActive
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFFB8D2),
                                          Color(0xFFFFD6E8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isDone || isActive ? null : Colors.white,
                                border: Border.all(
                                  color: isDone
                                      ? Colors.transparent
                                      : isActive
                                      ? const Color(0xFFFF9FB8)
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isActive
                                        ? Colors.pinkAccent.withOpacity(0.4)
                                        : Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 26,
                                      )
                                    : Text(
                                        "$day",
                                        style: TextStyle(
                                          fontSize: isActive ? 22 : 18,
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isActive
                                              ? const Color(0xFF2B2B2B)
                                              : Colors.black87,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- Карточки статистики ---
                    _buildStatCard(
                      "Завершено дней",
                      "$completedDays / $_totalDays",
                    ),
                    const SizedBox(height: 10),
                    _buildStatCard("Осталось", "$remainingDays дней"),

                    const SizedBox(height: 40),

                    // --- Мотивационное сообщение ---
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2B2B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF3A3A3A),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7BC8F8),
            ),
          ),
        ],
      ),
    );
  }
}
