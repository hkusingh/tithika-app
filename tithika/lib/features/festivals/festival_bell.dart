import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/festival_names.dart';
import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../state/providers.dart';

/// Per-festival reminder toggle.
///
/// Used both inline on a festival row and as a circular button on the festival
/// detail header, so the toggle semantics live in exactly one place.
///
/// The bell has three appearances, driven by the master "all festivals"
/// switch (see [NotificationSettings.festivalAlertsEnabled]):
///
///  * master on — lit but inert; every festival already notifies, so tapping
///    explains how to switch to individual selection rather than silently
///    rewriting a global setting from a list row.
///  * master off, selected — lit; tap removes it.
///  * master off, not selected — outline; tap adds it.
class FestivalBell extends ConsumerWidget {
  /// Canonical (English) festival key — the same string used by
  /// FestivalDetector, FestivalNames and the festival content assets.
  final String canonicalKey;

  final double size;

  /// True on the detail header's translucent black circle, where the theme's
  /// ink colours have too little contrast.
  final bool onDarkOverlay;

  const FestivalBell({
    super.key,
    required this.canonicalKey,
    this.size = 16,
    this.onDarkOverlay = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    // Select down to plain booleans rather than the settings object: every
    // copyWith returns a new instance (there is no ==), so watching the
    // object would rebuild all ~47 bells on every tap.
    final masterOn = ref.watch(appSettingsProvider
        .select((s) => s.notificationSettings.festivalAlertsEnabled));
    final notifsOn = ref
        .watch(appSettingsProvider.select((s) => s.notificationSettings.enabled));
    final selected = ref.watch(appSettingsProvider.select(
        (s) => s.notificationSettings.selectedFestivals.contains(canonicalKey)));
    final language =
        ref.watch(appSettingsProvider.select((s) => s.language));

    final lit = masterOn || selected;
    // Inert while the master switch covers everything, or while notifications
    // are switched off entirely — in both cases a tap can't change outcomes.
    final inert = masterOn || !notifsOn;

    final Color color;
    if (onDarkOverlay) {
      // Over photography, "lit" is carried by the gold rather than by white —
      // white reads as ordinary chrome next to the close button beside it.
      color = lit ? colors.shukla : Colors.white;
    } else {
      color = lit ? colors.shukla : colors.inkMuted;
    }

    // A photo behind the glyph swallows a faint icon, so dim far less there
    // than on a flat settings-style surface.
    final opacity = inert ? (onDarkOverlay ? 0.75 : 0.45) : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(context, ref, selected, language),
      child: Padding(
        // Pads a 16pt glyph out to a comfortable tap target. The row's own
        // GestureDetector is an ancestor, so this child wins the gesture
        // arena and the tap never opens the detail page. On the overlay the
        // enclosing 30pt circle is already the target, so no padding there.
        padding: onDarkOverlay
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Opacity(
          opacity: opacity,
          child: Icon(
            lit
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            size: size,
            color: color,
            shadows: onDarkOverlay
                ? const [Shadow(blurRadius: 4, color: Colors.black87)]
                : null,
          ),
        ),
      ),
    );
  }

  void _onTap(
    BuildContext context,
    WidgetRef ref,
    bool selected,
    AppLanguage language,
  ) {
    final notif =
        ref.read(appSettingsProvider).notificationSettings;

    // Nothing is scheduled at all while notifications are off, so writing a
    // selection here would have no effect the user could observe.
    if (!notif.enabled) {
      _snack(context, 'Turn on notifications in Settings first');
      return;
    }

    if (notif.festivalAlertsEnabled) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('All festivals are on'),
          content: const Text(
            'To choose individual festivals, turn off "All festivals" in '
            'Settings, then tap the bell on the ones you want.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    final updated = Set<String>.from(notif.selectedFestivals);
    if (selected) {
      updated.remove(canonicalKey);
    } else {
      updated.add(canonicalKey);
    }

    ref
        .read(appSettingsProvider.notifier)
        .setNotificationSettings(notif.copyWith(selectedFestivals: updated));

    // Belling a festival months out schedules nothing yet, so the snackbar is
    // the only confirmation the user gets.
    final name = FestivalNames.localize(canonicalKey, language) ?? canonicalKey;
    _snack(
      context,
      selected ? 'Reminder off for $name' : "You'll be reminded before $name",
    );
  }

  void _snack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    // Rapid taps down a list would otherwise queue a backlog of snackbars.
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
