import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 🔹 Импорт страниц
import 'auth_wrapper.dart';
import 'home_page.dart';
import 'profile_setup_page.dart';
import 'pages/profile_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализация Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Инициализация уведомлений
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitSphere',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),

      // 📍 Начальный экран
      home: const AuthWrapper(),

      // ✅ Регистрируем маршруты
      routes: {
        '/auth': (context) => const AuthWrapper(),
        '/home': (context) => const HomePage(),
        '/profile_setup': (context) => const ProfileSetupPage(),
        '/profile': (context) => const ProfilePage(),
      },

      // ✅ Обрабатываем переходы с анимацией
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/home':
            builder = (BuildContext _) => const HomePage();
            break;
          case '/auth':
            builder = (BuildContext _) => const AuthWrapper();
            break;
          case '/profile_setup':
            builder = (BuildContext _) => const ProfileSetupPage();
            break;
          case '/profile':
            builder = (BuildContext _) => const ProfilePage();
            break;
          default:
            builder = (BuildContext _) => const AuthWrapper();
        }

        // 🔹 Добавляем fade-анимацию
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            final tween = Tween(begin: begin, end: end);
            final fadeAnimation = animation.drive(tween);

            return FadeTransition(opacity: fadeAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
      },
    );
  }
}
