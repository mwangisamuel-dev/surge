import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_nav.dart';
import 'services/storage_service.dart';
import 'services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0C0C14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final storage = await StorageService.get();
  AiService.apiKey = storage.getApiKey();
  runApp(const SurgeApp());
}

class SurgeApp extends StatelessWidget {
  const SurgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surge',
      theme: SurgeTheme.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/home':   (_) => const MainNav(),
      },
    );
  }
}