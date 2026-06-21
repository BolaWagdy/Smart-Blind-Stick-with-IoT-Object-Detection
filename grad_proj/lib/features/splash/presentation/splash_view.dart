import 'package:flutter/material.dart';
import 'package:grad_proj/features/splash/presentation/widgets/splash_body.dart';
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SplashBody(),
    );
  }
}
