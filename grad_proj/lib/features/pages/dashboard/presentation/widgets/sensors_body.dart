import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';
class SensorsBody extends StatelessWidget {
  const SensorsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0)
            ),
            child: Icon(Icons.flash_on, color: AppColors.orange, size: 20),
          ),
          SizedBox(height: 8),
          Text("Sensors", style: TextStyle(fontSize: 14, color: Colors.black54)),
          SizedBox(height: 4),
          Text("12", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        ],
      ),
    );
  }
}
