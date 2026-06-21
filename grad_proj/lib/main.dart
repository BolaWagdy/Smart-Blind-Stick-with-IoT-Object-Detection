import 'package:flutter/material.dart';
import 'package:grad_proj/features/home_screen/presentation/home_screen.dart';
import 'package:grad_proj/features/splash/presentation/splash_view.dart';
import 'package:grad_proj/notification_service.dart';
import 'package:grad_proj/supabase_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseHelper.init();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        "HomeScreen": (context) => HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
      home: SplashView(),
    );
  }
}