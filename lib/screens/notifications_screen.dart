import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = result['success'] == true ? result['data'] : [];
        _isLoading = false;
      });
      NotificationService.markAllAsRead(); // Marquer comme lu dès qu'on ouvre
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brightGreen))
          : _notifications.isEmpty
              ? const Center(child: Text('Aucune notification', style: TextStyle(color: AppTheme.textGrey)))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderGreen),
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    String text = '';
                    if (n['notification_type'] == 'like') text = 'a aimé ta publication.';
                    if (n['notification_type'] == 'follow') text = 'a commencé à te suivre.';
                    if (n['notification_type'] == 'comment') text = 'a commenté ta publication.';

                    return ListTile(
                      tileColor: Colors.transparent, // <-- AJOUTE CA
                      leading: UserAvatar(username: n['sender_username'], photo: n['sender_photo'], radius: 22),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
                          children: [
                            TextSpan(text: '${n['sender_username']} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            TextSpan(text: text),
                          ],
                        ),
                      ),
                      subtitle: Text(timeago.format(DateTime.parse(n['created_at']), locale: 'fr'), style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                      trailing: !n['is_read'] ? const CircleAvatar(radius: 4, backgroundColor: AppTheme.brightGreen) : null,
                    );
                  },
                ),
    );
  }
}