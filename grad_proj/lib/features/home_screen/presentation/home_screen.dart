import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';
import 'package:grad_proj/core/widgets/custom_appbar.dart';
import 'package:grad_proj/features/pages/dashboard/presentation/weather_screen.dart';
import 'package:grad_proj/features/pages/map/presentation/map_screen.dart';
import 'package:grad_proj/features/pages/trends/presentation/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    MapScreen(),
    NotificationsScreen(),
    WeatherScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppbar(title: "Sensor Grid"),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  /// WEATHER
                  GestureDetector(
                    onTap: () => setState(() => currentIndex = 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: currentIndex == 2 ? 130 : 100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: currentIndex == 2
                            ? Colors.blue
                            : AppColors.BgColorWhite,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sunny,
                            color: currentIndex == 2
                                ? Colors.yellow
                                : Colors.grey,
                            size: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Weather",
                            style: TextStyle(
                              color: currentIndex == 2
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// MAP
                  GestureDetector(
                    onTap: () => setState(() => currentIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: currentIndex == 0 ? 130 : 100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: currentIndex == 0
                            ? Colors.blue
                            : AppColors.BgColorWhite,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: currentIndex == 0
                                ? Colors.redAccent
                                : Colors.grey,
                            size: 28,
                            fontWeight: FontWeight.bold,

                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Map",
                            style: TextStyle(
                              color: currentIndex == 0
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// NOTIFICATIONS
                  GestureDetector(
                    onTap: () => setState(() => currentIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: currentIndex == 1 ? 130 : 100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: currentIndex == 1
                            ? Colors.blue
                            : AppColors.BgColorWhite,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: currentIndex == 1
                                ? Colors.orangeAccent
                                : Colors.grey,
                            size: 28,
                            fontWeight: FontWeight.bold,

                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Notifications",
                            style: TextStyle(
                              color: currentIndex == 1
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: screens[currentIndex]),
          ],
        ),
      ),
    );
  }
}
