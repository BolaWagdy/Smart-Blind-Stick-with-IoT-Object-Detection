import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue, AppColors.teal,
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
