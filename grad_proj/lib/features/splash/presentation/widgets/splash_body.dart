import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:grad_proj/core/resourses/assets.dart';
import 'package:grad_proj/core/resourses/assets.dart';

class SplashBody extends StatefulWidget {
  const SplashBody({super.key});

  @override
  State<SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<SplashBody> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;


  @override
  void initState() {
    animationFunction();
    Future.delayed(Duration(seconds: 4),(){
      Navigator.pushReplacementNamed(context, "HomeScreen");
    });
    // TODO: implement initState
    super.initState();
  }
  animationFunction(){
    animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: animationController, curve: Curves.easeIn));
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage(AssetImages.logo2)),
          ),
          width: 350,
          height: 225,
        ),
      ),
    );
  }

}

