import 'package:flutter/material.dart';
import 'package:grad_proj/features/pages/trends/presentation/widgets/bottom_stats_body.dart';
import 'package:grad_proj/features/pages/trends/presentation/widgets/data_period_body.dart';
import 'package:grad_proj/features/pages/trends/presentation/widgets/water_level_trends_body.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              /// Data Period
              DataPeriodBody(),

              SizedBox(height: 20),

              /// Water Level Trends
              WaterLevelTrendsBody(),

              SizedBox(height: 20),

              /// Bottom Stats
              BottomStatsBody(),
            ],
          ),
        ),
      ),
    );
  }
}
