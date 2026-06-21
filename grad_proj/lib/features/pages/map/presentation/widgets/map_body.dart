import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapBody extends StatefulWidget {
  const MapBody({super.key});

  @override
  State<MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<MapBody> with TickerProviderStateMixin {
  AnimatedMapController? _animatedMapController;

  LatLng? currentLocation;
  bool loading = true;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _animatedMapController = AnimatedMapController(vsync: this);

    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final data = await supabase
          .from('gps_locations')
          .select('lat, lng')
          .order('id', ascending: false)
          .limit(1);

      if (data.isEmpty) {
        setState(() => loading = false);
        return;
      }

      final item = data.first;

      final lat = num.tryParse(item['lat']?.toString() ?? '');
      final lng = num.tryParse(item['lng']?.toString() ?? '');

      if (lat == null || lng == null) return;

      final newLocation = LatLng(lat.toDouble(), lng.toDouble());

      if (!mounted) return;

      setState(() {
        currentLocation = newLocation;
        loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animatedMapController?.animateTo(
          dest: newLocation,
          zoom: 15,
          rotation: 0,
        );
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Supabase error: $e");
    }
  }

  @override
  void dispose() {
    _animatedMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _animatedMapController;

    if (controller == null || loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  initialCenter: currentLocation ??
                      const LatLng(30.0444, 31.2357),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                  ),

                  MarkerLayer(
                    markers: currentLocation == null
                        ? []
                        : [
                      Marker(
                        point: currentLocation!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          size: 45,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "GPS Location",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              Positioned(
                bottom: 12,
                right: 12,
                child: InkWell(
                  onTap: _fetchLocation,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_pin, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}