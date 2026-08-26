import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/app_location.dart';
import '../../models/app_settings.dart';
import '../../models/eclipse_info.dart';

void showEclipseDetail(
  BuildContext context,
  EclipseInfo eclipse,
  AppLanguage language,
  AppLocation location,
) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black54,
      pageBuilder: (ctx, _, __) => _EclipseDetailPage(
        eclipse: eclipse,
        language: language,
        location: location,
      ),
      transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

/// Formats an eclipse-related UTC instant for display. When the eclipse is
/// visible at [location], converts to local time (there is a real, local
/// observation to report). When not visible, these instants only describe
/// the eclipse's global path — not anything happening at [location] — so
/// they're shown in UTC, explicitly labelled, rather than silently
/// reinterpreted through a timezone where nothing is actually observed.
String _formatEclipseTime(DateTime utc, AppLocation location, bool visible) {
  if (!visible) return '${formatLocalDatetime(utc, Duration.zero)} UTC';
  // tzOffsetAt expects a local calendar date, not a UTC instant — approximate
  // via the fixed fallback offset first to land on the right calendar date,
  // then re-resolve the precise DST-aware offset for that date.
  final approxLocal = utc.add(Duration(minutes: location.tzOffsetMinutes));
  final approxLocalDate = DateTime(approxLocal.year, approxLocal.month, approxLocal.day);
  final tzOffset = location.tzOffsetAt(approxLocalDate);
  return formatLocalDatetime(utc, tzOffset);
}

class _EclipseDetailPage extends StatelessWidget {
  final EclipseInfo eclipse;
  final AppLanguage language;
  final AppLocation location;

  const _EclipseDetailPage({
    required this.eclipse,
    required this.language,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = eclipse.localDate;
    final gregDate = '${wd[d.weekday - 1]}, ${mo[d.month - 1]} ${d.day}';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, bottomPad + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.eclipse.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppStrings.eclipses(language),
                      style: TextStyle(
                        color: colors.eclipse,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: colors.inkSoft, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.eclipseFullName(eclipse.kind, eclipse.subtype, language),
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gregDate,
                style: TextStyle(color: colors.inkSoft, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (eclipse.visible ? colors.shukla : colors.inkMuted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      eclipse.visible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 16,
                      color: eclipse.visible ? colors.shukla : colors.inkMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eclipse.visible
                          ? AppStrings.eclipseVisible(language)
                          : AppStrings.eclipseNotVisible(language),
                      style: TextStyle(
                        color: eclipse.visible ? colors.shukla : colors.inkMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    if (!eclipse.visible) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          AppStrings.eclipseTimesInUtc(language),
                          style: TextStyle(color: colors.inkMuted, fontSize: 11),
                        ),
                      ),
                    ],
                    if (eclipse.sutakStartUtc != null) ...[
                      _TimeRow(
                        label: AppStrings.sutakBegins(language),
                        time: _formatEclipseTime(eclipse.sutakStartUtc!, location, eclipse.visible),
                        colors: colors,
                        emphasize: true,
                      ),
                      Divider(height: 20, color: colors.line),
                    ],
                    _TimeRow(
                      label: AppStrings.eclipseStart(language),
                      time: _formatEclipseTime(eclipse.startUtc, location, eclipse.visible),
                      colors: colors,
                    ),
                    const SizedBox(height: 10),
                    _TimeRow(
                      label: AppStrings.eclipseMax(language),
                      time: _formatEclipseTime(eclipse.maxUtc, location, eclipse.visible),
                      colors: colors,
                    ),
                    const SizedBox(height: 10),
                    _TimeRow(
                      label: AppStrings.eclipseEnd(language),
                      time: _formatEclipseTime(eclipse.endUtc, location, eclipse.visible),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String time;
  final TithikaColors colors;
  final bool emphasize;

  const _TimeRow({
    required this.label,
    required this.time,
    required this.colors,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: emphasize ? colors.eclipse : colors.inkSoft,
            fontSize: 13,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: emphasize ? colors.eclipse : colors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
