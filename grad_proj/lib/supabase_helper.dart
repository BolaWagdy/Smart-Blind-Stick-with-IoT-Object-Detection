import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://dendsqemydqkhhwstzpa.supabase.co/',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbmRzcWVteWRxa2hod3N0enBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3Mjk0MzEsImV4cCI6MjA5MzMwNTQzMX0.5l8B5xw7X1WyHUTymf-GHlF2qu58Uv4apHnPSTbAHsM',
    );
  }
}
