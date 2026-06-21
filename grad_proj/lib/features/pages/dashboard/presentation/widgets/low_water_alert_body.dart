import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';
class LowWaterAlertBody extends StatelessWidget {
  const LowWaterAlertBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepOrange, AppColors.burgundy,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.BgColorWhite, size: 28),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Low Water Alert", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.BgColorWhite, fontSize: 16)),
                Text("Station Beta showing critically low levels", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: AppColors.BgColorWhite,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('View', style: TextStyle(color: AppColors.deepOrange,fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
