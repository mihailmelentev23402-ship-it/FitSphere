import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _desiredWeightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedGoal;
  bool _isLoading = false;

  final List<String> _goals = [
    "Сбросить вес",
    "Набрать мышечную массу",
    "Поддерживать форму",
  ];

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'weight': int.parse(_weightController.text.trim()),
        'desiredWeight': int.parse(_desiredWeightController.text.trim()),
        'height': int.parse(_heightController.text.trim()),
        'age': int.parse(_ageController.text.trim()),
        'goal': _selectedGoal,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Заполни профиль",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB6E3FF), Color(0xFFFFD6E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 120),
                const Text(
                  "Расскажи немного о себе 💬",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Эти данные помогут FitSphere подобрать идеальную программу тренировок 💪",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // Имя
                _buildTextField(
                  label: "Имя",
                  icon: Icons.person_outline,
                  controller: _nameController,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Введите имя" : null,
                ),
                const SizedBox(height: 16),

                // Текущий вес
                _buildTextField(
                  label: "Текущий вес (кг)",
                  icon: Icons.fitness_center,
                  controller: _weightController,
                  type: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Введите вес" : null,
                ),
                const SizedBox(height: 16),

                // Желаемый вес
                _buildTextField(
                  label: "Желаемый вес (кг)",
                  icon: Icons.flag_outlined,
                  controller: _desiredWeightController,
                  type: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Введите желаемый вес" : null,
                ),
                const SizedBox(height: 16),

                // Рост
                _buildTextField(
                  label: "Рост (см)",
                  icon: Icons.height,
                  controller: _heightController,
                  type: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Введите рост" : null,
                ),
                const SizedBox(height: 16),

                // Возраст
                _buildTextField(
                  label: "Возраст",
                  icon: Icons.cake_outlined,
                  controller: _ageController,
                  type: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Введите возраст" : null,
                ),
                const SizedBox(height: 20),

                // Цель
                DropdownButtonFormField<String>(
                  value: _selectedGoal,
                  items: _goals
                      .map(
                        (goal) => DropdownMenuItem(
                          value: goal,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.track_changes_outlined,
                                color: Colors.deepPurpleAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(goal),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGoal = v),
                  decoration: InputDecoration(
                    labelText: "Ваша цель",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      v == null ? "Пожалуйста, выберите цель" : null,
                ),
                const SizedBox(height: 40),

                // Кнопка сохранения
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onTap: _saveProfile,
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7BC8F8), Color(0xFFFFA8C8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Сохранить",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
