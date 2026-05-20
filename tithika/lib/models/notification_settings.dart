class NotificationSettings {
  final bool enabled;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final bool festivalAlertsEnabled;
  final bool ekadashiAlertsEnabled;

  const NotificationSettings({
    this.enabled = false,
    this.dailyReminderEnabled = true,
    this.dailyReminderHour = 7,
    this.dailyReminderMinute = 0,
    this.festivalAlertsEnabled = true,
    this.ekadashiAlertsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? festivalAlertsEnabled,
    bool? ekadashiAlertsEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      festivalAlertsEnabled:
          festivalAlertsEnabled ?? this.festivalAlertsEnabled,
      ekadashiAlertsEnabled:
          ekadashiAlertsEnabled ?? this.ekadashiAlertsEnabled,
    );
  }
}
