import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/detection_screen.dart';
import 'screens/result_screen.dart';
import 'screens/multi_result_screen.dart';
import 'screens/detail_check_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EggCheckApp());
}

class EggCheckApp extends StatelessWidget {
  const EggCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EggCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/detection': (context) => const DetectionScreen(),
        '/result': (context) => const ResultScreen(),
        '/multi_result': (context) => const MultiResultScreen(),
        '/detail_check': (context) => const DetailCheckScreen(),
      },
    );
  }
}
