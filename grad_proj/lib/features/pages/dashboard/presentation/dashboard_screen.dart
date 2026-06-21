import 'package:flutter/material.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/widgets/active_stations_body.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/widgets/aquifers_body.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/widgets/avg_water_level_body.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/widgets/coverage_body.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/widgets/low_water_alert_body.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/widgets/recharge_rate_body.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/widgets/sensors_body.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),

            // Avg , Rate
            Row(
              children: [
                // Avg Water Level
                AvgWaterLevelBody(),

                SizedBox(width: 16),

                // Recharge Rate
                RechargeRateBody(),
              ],
            ),

            SizedBox(height: 16),

            // Low Water Alert
            LowWaterAlertBody(),

            SizedBox(height: 16),

            // Active Stations
            ActiveStationsBody(),

            SizedBox(height: 24),


            Row(
              children: [
                // Sensors
                SensorsBody(),
                // Aquifers
                AquifersBody(),
                // Coverage
                CoverageBody(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
