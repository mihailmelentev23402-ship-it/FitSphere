import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_page.dart';
import 'home_page.dart';
import 'profile_setup_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isProfileComplete(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data();
    if (data == null) return false;

    return data['weight'] != null &&
        data['height'] != null &&
        data['age'] != null &&
        data['goal'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Загружается
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Пользователь не вошёл
        if (!snapshot.hasData) {
          return const AuthPage();
        }

        // 3. Пользователь вошёл → проверяем профиль
        final user = snapshot.data!;
        return FutureBuilder<bool>(
          future: _isProfileComplete(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text("Ошибка загрузки профиля")),
              );
            }

            final isComplete = profileSnapshot.data ?? false;
            if (!isComplete) {
              return const ProfileSetupPage();
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
