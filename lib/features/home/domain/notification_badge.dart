class NotificationBadge {
  const NotificationBadge({required this.unreadCount});

  factory NotificationBadge.fromJson(Map<String, dynamic> json) {
    return NotificationBadge(unreadCount: json['count'] as int);
  }

  final int unreadCount;
}
