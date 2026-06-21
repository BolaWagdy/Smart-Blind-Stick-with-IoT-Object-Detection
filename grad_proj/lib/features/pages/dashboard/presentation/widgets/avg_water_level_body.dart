import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';
class AvgWaterLevelBody extends StatelessWidget {
  const AvgWaterLevelBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blue, AppColors.skyBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Avg Water Level", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration:
                  BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Live',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text("44.2m", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),

      ),
    );
  }
}
