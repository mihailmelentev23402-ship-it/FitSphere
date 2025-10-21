import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _nutrition;
  List<String> _menu = [];

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
      final data = doc.data()!;
      setState(() {
        _profile = data;
        _nutrition = _calculateNutrition(data);
        _menu = _generateRandomMenu(data['goal'] ?? "Поддерживать форму");
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _calculateNutrition(Map<String, dynamic> profile) {
    final int age = profile['age'] ?? 25;
    final double weight = (profile['weight'] ?? 70).toDouble();
    final double desiredWeight = (profile['desiredWeight'] ?? weight)
        .toDouble();
    final double height = (profile['height'] ?? 170).toDouble();
    final String goal = profile['goal'] ?? "Поддерживать форму";

    final bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    final maintenance = bmr * 1.375;

    double calories;
    if (goal == "Сбросить вес" || desiredWeight < weight) {
      calories = maintenance - 400;
    } else if (goal == "Набрать мышечную массу" || desiredWeight > weight) {
      calories = maintenance + 400;
    } else {
      calories = maintenance;
    }

    final protein = (calories * 0.3 / 4).round();
    final fats = (calories * 0.25 / 9).round();
    final carbs = (calories * 0.45 / 4).round();

    return {
      "calories": calories.round(),
      "protein": protein,
      "fats": fats,
      "carbs": carbs,
    };
  }

  List<String> _generateRandomMenu(String goal) {
    final random = Random();

    final breakfastsLose = [
      "Омлет из 2 яиц + овощи",
      "Овсянка на воде + яблоко",
      "Греческий йогурт + ягоды",
    ];
    final lunchesLose = [
      "Куриная грудка + гречка + салат",
      "Рыба на пару + овощи",
      "Индейка + тушёные овощи",
    ];
    final dinnersLose = ["Рыба + салат", "Творог 150 г + ягоды", "Овощной суп"];

    final breakfastsGain = [
      "Овсянка на молоке + банан + орехи",
      "Яичница из 3 яиц + хлеб + авокадо",
      "Творог с мёдом и сухофруктами",
    ];
    final lunchesGain = [
      "Говядина + рис + овощи",
      "Курица + макароны + салат",
      "Лосось + картофель + овощи",
    ];
    final dinnersGain = [
      "Куриная грудка + картофельное пюре",
      "Творог + банан",
      "Омлет с овощами",
    ];

    final breakfastsMaintain = [
      "Омлет с овощами",
      "Овсянка + фрукты",
      "Творог + ягоды",
    ];
    final lunchesMaintain = [
      "Курица + гречка + овощи",
      "Рыба + рис + салат",
      "Индейка + овощи",
    ];
    final dinnersMaintain = [
      "Рыба + овощи",
      "Творог + фрукты",
      "Омлет с овощами",
    ];

    if (goal == "Сбросить вес") {
      return [
        "Завтрак: ${breakfastsLose[random.nextInt(breakfastsLose.length)]}",
        "Обед: ${lunchesLose[random.nextInt(lunchesLose.length)]}",
        "Ужин: ${dinnersLose[random.nextInt(dinnersLose.length)]}",
      ];
    } else if (goal == "Набрать мышечную массу") {
      return [
        "Завтрак: ${breakfastsGain[random.nextInt(breakfastsGain.length)]}",
        "Обед: ${lunchesGain[random.nextInt(lunchesGain.length)]}",
        "Ужин: ${dinnersGain[random.nextInt(dinnersGain.length)]}",
      ];
    } else {
      return [
        "Завтрак: ${breakfastsMaintain[random.nextInt(breakfastsMaintain.length)]}",
        "Обед: ${lunchesMaintain[random.nextInt(lunchesMaintain.length)]}",
        "Ужин: ${dinnersMaintain[random.nextInt(dinnersMaintain.length)]}",
      ];
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Питание",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _menu = _generateRandomMenu(_profile!['goal']);
          });
        },
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB6E3FF), Color(0xFFFFD6E8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Твой план питания на сегодня 🍎",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Калорийность ---
                _buildCaloriesCard(),

                const SizedBox(height: 30),

                // --- БЖУ карточки ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMacroCard(
                      "Белки",
                      "${_nutrition!['protein']} г",
                      Colors.blueAccent,
                    ),
                    _buildMacroCard(
                      "Жиры",
                      "${_nutrition!['fats']} г",
                      Colors.orange,
                    ),
                    _buildMacroCard(
                      "Углеводы",
                      "${_nutrition!['carbs']} г",
                      Colors.pink,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // --- Меню ---
                const Text(
                  "Пример меню:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                const SizedBox(height: 15),

                ..._menu.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final icons = [
                    Icons.breakfast_dining,
                    Icons.lunch_dining,
                    Icons.dinner_dining,
                  ];
                  return _buildMealCard(item, icons[index]);
                }),

                const SizedBox(height: 30),
                const Text(
                  "Потяни вниз, чтобы обновить меню 🔄",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Рекомендуемая калорийность",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${_nutrition!['calories']} ккал",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2B2B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, Color color) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String meal, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7BC8F8), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              meal,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
