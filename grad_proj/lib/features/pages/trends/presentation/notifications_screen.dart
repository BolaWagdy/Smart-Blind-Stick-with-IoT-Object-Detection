import 'package:flutter/material.dart';
import 'package:grad_proj/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt.toString()).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year  $hour:$minute';
    } catch (e) {
      return '';
    }
  }

  Future<void> deleteNotification(dynamic id) async {
    await supabase.from('mpu_fall_detected').delete().eq('id', id);
    setState(() {
      notifications.removeWhere((n) => n['id'] == id);
    });
  }

  Future<void> clearAll() async {
    // confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ids = notifications.map((n) => n['id']).toList();
    for (final id in ids) {
      await supabase.from('mpu_fall_detected').delete().eq('id', id);
    }
    setState(() => notifications.clear());
  }

  void _subscribeToRealtime() {
    _channel = supabase
        .channel('mpu_fall_channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'mpu_fall_detected',
      callback: (payload) async {
        print("🔔 Realtime received: ${payload.newRecord}");
        final data = Map<String, dynamic>.from(payload.newRecord);
        print("🔔 fall_detected value: ${data['fall_detected']}");
        print("🔔 fall_detected type: ${data['fall_detected'].runtimeType}");

        if (data['fall_detected'] == true) {
          setState(() {
            notifications.insert(0, {
              'id': data['id'],
              'title': 'Emergency Alert 🚨',
              'body': 'The cane has fallen!\nStatus: ${data['status']}',
              'is_read': false,
              'created_at': data['created_at'],
            });
          });

          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService.showAlarm(
                ctx,
                'Emergency Alert 🚨',
                'The cane has fallen!\nStatus: ${data['status']}',
              );
            });
          }
        }
      },
    )
        .subscribe((status, [error]) {
      print("🔔 Realtime status: $status");
      if (error != null) print("🔔 Realtime error: $error");
    });
  }

  Future<void> fetchNotifications() async {
    try {
      final data = await supabase
          .from('mpu_fall_detected')
          .select()
          .eq('fall_detected', true)
          .order('created_at', ascending: false);

      setState(() {
        notifications = List<Map<String, dynamic>>.from(data).map((d) => {
          'id': d['id'],
          'title': 'Emergency Alert 🚨',
          'body': 'The cane has fallen!\nStatus: ${d['status']}',
          'is_read': false,
          'created_at': d['created_at'],
        }).toList();
        loading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: clearAll,
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: loading
                    ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue))
                    : notifications.isEmpty
                    ? const Center(child: Text("No notifications"))
                    : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['body'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(n['created_at']),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // زر حذف الـ notification
                          GestureDetector(
                            onTap: () => deleteNotification(n['id']),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}