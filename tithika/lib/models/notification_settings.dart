/// Upper bound for [NotificationSettings.alertDaysBefore]. The scheduling
/// lookahead is `7 + alertDaysBefore` days, so this bounds that window too.
const maxAlertDaysBefore = 3;

class NotificationSettings {
  final bool enabled;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;

  /// Master "all festivals" switch.
  ///
  /// When true, every festival notifies — a blanket subscription. When false,
  /// only the festivals in [selectedFestivals] notify. False therefore does
  /// NOT mean silence; it means "individually chosen". Use [notifiesFor] and
  /// [noFestivalAlerts] rather than reading this flag directly.
  final bool festivalAlertsEnabled;

  final bool ekadashiAlertsEnabled;
  final bool purnimaAlertsEnabled;
  final bool amavasyaAlertsEnabled;

  /// Festivals the user has opted into individually, by canonical (English)
  /// festival key. Only consulted when [festivalAlertsEnabled] is false, but
  /// kept independently of it so toggling the master switch on and back off
  /// restores the previous selection rather than discarding it.
  ///
  /// Treat as read-only: callers build a new set and pass it to [copyWith]
  /// rather than mutating this one. (It can't be wrapped in
  /// `Set.unmodifiable` here without giving up the const constructor that
  /// `AppSettings`'s default value needs.)
  final Set<String> selectedFestivals;

  /// How many days before the event observance alerts fire (0–3).
  /// Shared by festival, Ekadashi, Purnima and Amavasya alerts.
  final int alertDaysBefore;
  final int alertHour;
  final int alertMinute;

  const NotificationSettings({
    this.enabled = false,
    this.dailyReminderEnabled = true,
    this.dailyReminderHour = 7,
    this.dailyReminderMinute = 0,
    this.festivalAlertsEnabled = true,
    this.ekadashiAlertsEnabled = true,
    this.purnimaAlertsEnabled = true,
    this.amavasyaAlertsEnabled = true,
    this.selectedFestivals = const <String>{},
    this.alertDaysBefore = 1,
    this.alertHour = 6,
    this.alertMinute = 0,
  });

  /// True when [key] should notify: the master switch covers everything,
  /// otherwise only explicitly selected festivals.
  bool notifiesFor(String key) =>
      festivalAlertsEnabled || selectedFestivals.contains(key);

  /// True when no festival will notify at all — the master switch is off and
  /// nothing has been selected individually.
  bool get noFestivalAlerts =>
      !festivalAlertsEnabled && selectedFestivals.isEmpty;

  NotificationSettings copyWith({
    bool? enabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? festivalAlertsEnabled,
    bool? ekadashiAlertsEnabled,
    bool? purnimaAlertsEnabled,
    bool? amavasyaAlertsEnabled,
    Set<String>? selectedFestivals,
    int? alertDaysBefore,
    int? alertHour,
    int? alertMinute,
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
      purnimaAlertsEnabled: purnimaAlertsEnabled ?? this.purnimaAlertsEnabled,
      amavasyaAlertsEnabled:
          amavasyaAlertsEnabled ?? this.amavasyaAlertsEnabled,
      selectedFestivals: selectedFestivals ?? this.selectedFestivals,
      alertDaysBefore: alertDaysBefore ?? this.alertDaysBefore,
      alertHour: alertHour ?? this.alertHour,
      alertMinute: alertMinute ?? this.alertMinute,
    );
  }
}
