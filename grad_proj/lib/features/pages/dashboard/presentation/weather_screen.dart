import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  double temperature = 0;
  int tempMax = 0;
  int tempMin = 0;
  int humidity = 0;
  double windSpeed = 0;
  int weatherCode = 0;
  double precipitation = 0;
  bool loading = true;

  late AnimationController _mainController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _tempCountAnim;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(
      begin: 40,
      end: 0,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));
    _floatAnim = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _tempCountAnim = Tween<double>(begin: 0, end: 0).animate(_mainController);

    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final data = await supabase
          .from('gps_locations')
          .select()
          .order('id', ascending: false)
          .limit(1)
          .single();

      setState(() {
        temperature = (data['temperature'] ?? 0).toDouble();
        tempMax = (data['temp_max'] ?? 0).toInt();
        tempMin = (data['temp_min'] ?? 0).toInt();
        humidity = (data['humidity'] ?? 0);
        windSpeed = (data['wind_speed'] ?? 0).toDouble();
        weatherCode = (data['weather_code'] ?? 0);
        precipitation = (data['precipitation'] ?? 0).toDouble();
        loading = false;
      });

      _tempCountAnim = Tween<double>(begin: 0, end: temperature).animate(
        CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
      );

      _mainController.forward();
    } catch (e) {
      setState(() => loading = false);
    }
  }

  String getWeatherEmoji() {
    if (weatherCode < 2) return '☀️';
    if (weatherCode < 4) return '⛅';
    if (weatherCode < 6) return '🌥️';
    if (weatherCode < 8) return '🌧️';
    return '⛈️';
  }

  String getConditionText() {
    if (weatherCode < 2) return 'CLEAR SKY';
    if (weatherCode < 4) return 'PARTLY CLOUDY';
    if (weatherCode < 6) return 'CLOUDY';
    if (weatherCode < 8) return 'RAINY';
    return 'THUNDERSTORM';
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F5F9);
    const dark = Color(0xFF1e2a3a);
    const muted = Color(0xFF9aa3b0);
    const borderColor = Color(0xFFe2e8f0);

    if (loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF378ADD)),
        ),
      );
    }

    final rainPct = ((precipitation / 10) * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    "Today's Weather",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: dark,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Floating emoji
                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFe2e8f0)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: child,
                            ),
                            child: Text(
                              getWeatherEmoji(),
                              style: const TextStyle(fontSize: 72),
                            ),
                          ),

                          const SizedBox(height: 18),

                          AnimatedBuilder(
                            animation: _tempCountAnim,
                            builder: (context, _) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_tempCountAnim.value.round()}',
                                  style: const TextStyle(
                                    fontSize: 82,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1e2a3a),
                                    height: 1,
                                    letterSpacing: -4,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    '°',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF9aa3b0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            getConditionText(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9aa3b0),
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFf87171),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'High',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9aa3b0),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$tempMax°',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1e2a3a),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF60a5fa),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Low',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9aa3b0),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$tempMin°',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1e2a3a),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: borderColor, thickness: 1),
                  const SizedBox(height: 22),

                  // Stats row
                  Row(
                    children: [
                      // Wind
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFe2e8f0)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              const Center(
                                child: Text(
                                  '💨',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${windSpeed.round()} km/h',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1e2a3a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Wind',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9aa3b0),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Humidity
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFe2e8f0)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              const Center(
                                child: Text(
                                  '💧',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '$humidity%',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1e2a3a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Humidity',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9aa3b0),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Rain
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFe2e8f0)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              const Center(
                                child: Text(
                                  '🌧️',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '$rainPct%',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1e2a3a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Rain',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9aa3b0),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
