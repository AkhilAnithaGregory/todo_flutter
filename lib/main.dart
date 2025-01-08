import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_page.dart';
import 'screens/todo_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  String? loginToken = prefs.getString('loginToken');

  runApp(MyApp(
      initialRoute:
          loginToken != null && loginToken.isNotEmpty ? 'dashboard' : 'login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: {
        'login': (context) => const LoginPage(),
        'dashboard': (context) => const Dashboard(),
      },
    );
  }
}
