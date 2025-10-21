import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import 'achievements_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _profile;

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
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  Future<void> _editField(String field, dynamic currentValue) async {
    final controller = TextEditingController(
      text: currentValue?.toString() ?? "",
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Изменить $field"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Введите новое значение"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        field: result,
      }, SetOptions(merge: true));

      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text("Профиль не найден")));
    }

    final String userName = _profile!['name'] ?? "Пользователь";
    final int currentDay = (_profile!['lastCompletedDay'] ?? 0) + 1;
    const int totalDays = 30;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Профиль",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB6E3FF), Color(0xFFFFD6E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
          children: [
            // --- Аватар и приветствие ---
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "F",
                    style: const TextStyle(
                      fontSize: 40,
                      color: Color(0xFF7BC8F8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Здравствуйте, $userName 👋",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- Информация ---
            _buildSectionTitle("Личная информация"),
            const SizedBox(height: 10),
            _buildInfoCard("Имя", _profile!['name'], Icons.person, () {
              _editField("name", _profile!['name']);
            }),
            _buildInfoCard("Возраст", _profile!['age'], Icons.cake, () {
              _editField("age", _profile!['age']);
            }),
            _buildInfoCard(
              "Рост",
              "${_profile!['height']} см",
              Icons.height,
              () => _editField("height", _profile!['height']),
            ),
            _buildInfoCard(
              "Вес",
              "${_profile!['weight']} кг",
              Icons.monitor_weight,
              () => _editField("weight", _profile!['weight']),
            ),
            _buildInfoCard("Цель", _profile!['goal'], Icons.flag, () {
              _editField("goal", _profile!['goal']);
            }),

            const SizedBox(height: 25),

            // --- Прогресс ---
            _buildSectionTitle("Прогресс"),
            const SizedBox(height: 10),
            _buildProgressCard(currentDay, totalDays),

            const SizedBox(height: 25),

            // --- Достижения ---
            _buildSectionTitle("Достижения"),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementsPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Посмотреть мои достижения",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --- Настройки ---
            _buildSectionTitle("Настройки"),
            const SizedBox(height: 10),
            _buildGradientButton(
              text: "Проверить уведомление 🔔",
              onPressed: () {
                NotificationService.showInstantNotification(
                  title: 'Пора на тренировку 💪',
                  body: 'Не забудь сделать разминку сегодня!',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Уведомление отправлено")),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildGradientButton(
              text: "Выйти из аккаунта 🚪",
              onPressed: _logout,
              colors: [Colors.redAccent, Colors.orangeAccent],
            ),
          ],
        ),
      ),
    );
  }

  // --- Вспомогательные виджеты ---
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2B2B2B),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    dynamic value,
    IconData icon,
    VoidCallback onEdit,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7BC8F8)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int current, int total) {
    final percent = (current / total * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Дневной прогресс",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              Text(
                "$percent%",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7BC8F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7BC8F8),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "День $current из $total",
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    List<Color>? colors,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                colors ?? [const Color(0xFF7BC8F8), const Color(0xFFB6E3FF)],
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
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
