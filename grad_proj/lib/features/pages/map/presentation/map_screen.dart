import 'package:flutter/material.dart';
import 'package:grad_proj/features/pages/map/presentation/widgets/map_body.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),

      body: SafeArea(
        child: Column(
          children: [
            // MAP AREA (fixed + smooth)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MapBody(),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}