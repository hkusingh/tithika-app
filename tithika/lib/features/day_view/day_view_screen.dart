import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/festival_names.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/app_settings.dart';
import '../../models/day_data.dart';
import '../../models/lunar_month.dart';
import '../../models/paksha.dart';
import '../../services/festival_detector.dart';
import '../../services/providers.dart' as svc;
import '../../state/providers.dart';
import '../shared/starfield_background.dart';
import 'location_banner.dart';
import 'moon_phase_widget.dart';

DayData _applyMonthSystem(DayData raw, MonthSystem system) {
  if (system == MonthSystem.amanta) return raw;
  if (!raw.isAdhika && raw.tithi.paksha == Paksha.krishna) {
    final next = LunarMonth.values[(raw.lunarMonth.index + 1) % 12];
    return raw.copyWith(lunarMonth: next);
  }
  return raw;
}

// Fixed epoch for converting dates ↔ PageView page indices.
// Use UTC to avoid DST-related off-by-one errors in difference().
final _epoch = DateTime.utc(2000, 1, 1);

int _dateToPage(DateTime d) {
  final utc = DateTime.utc(d.year, d.month, d.day);
  return utc.difference(_epoch).inDays + 100000;
}

DateTime _pageToDate(int page) {
  final utc = _epoch.add(Duration(days: page - 100000));
  return DateTime(utc.year, utc.month, utc.day);
}

class DayViewScreen extends ConsumerStatefulWidget {
  const DayViewScreen({super.key});

  @override
  ConsumerState<DayViewScreen> createState() => _DayViewScreenState();
}

class _DayViewScreenState extends ConsumerState<DayViewScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _dateToPage(ref.read(selectedDateProvider)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(effectiveLocationProvider);
    final date = ref.watch(selectedDateProvider);

    // Sync PageController to selectedDateProvider after every build.
    // Using addPostFrameCallback ensures the PageView is laid out before we
    // jump, and handles the case where selectedDateProvider changed before this
    // listener was registered (e.g. a tap in month view just before go('/') ).
    final target = _dateToPage(date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if ((_controller.page?.round() ?? target) != target) {
        _controller.jumpToPage(target);
      }
    });

    // Keep selectedMonthProvider in sync so month view opens at the right month.
    ref.listen<DateTime>(selectedDateProvider, (prev, next) {
      if (prev == null || prev.month != next.month || prev.year != next.year) {
        ref.read(selectedMonthProvider.notifier).state =
            DateTime(next.year, next.month);
      }
    });

    final localNow = DateTime.now().toUtc().add(location.tzOffset);
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                const LocationBanner(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Absolutely centered Today button
                        if (!isToday)
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(selectedDateProvider.notifier)
                                  .state = today;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: TithikaColors.shukla
                                        .withValues(alpha: 0.6)),
                                borderRadius: BorderRadius.circular(20),
                                color: TithikaColors.shukla
                                    .withValues(alpha: 0.08),
                              ),
                              child: Text(
                                'Today',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: TithikaColors.shukla,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          ),
                        // Left: app name
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tithika',
                            style: TextStyle(
                              color: TithikaColors.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Right: action icons
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.flare_rounded,
                                    color: TithikaColors.inkSoft, size: 22),
                                onPressed: () => context.go('/festivals'),
                                tooltip: 'Festivals',
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_month_rounded,
                                    color: TithikaColors.inkSoft, size: 22),
                                onPressed: () => context.go('/month'),
                                tooltip: 'Month view',
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune_rounded,
                                    color: TithikaColors.inkSoft, size: 22),
                                onPressed: () => context.go('/settings'),
                                tooltip: 'Settings',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 85,
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (page) {
                      final newDate = _pageToDate(page);
                      if (newDate != ref.read(selectedDateProvider)) {
                        ref.read(selectedDateProvider.notifier).state = newDate;
                      }
                    },
                    itemBuilder: (context, page) =>
                        _DayPageContent(date: _pageToDate(page)),
                  ),
                ),
                const Expanded(flex: 15, child: _DayStrip()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-page content ──────────────────────────────────────────────────────────

class _DayPageContent extends ConsumerWidget {
  final DateTime date;
  const _DayPageContent({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tithiSvcAsync = ref.watch(svc.tithiServiceProvider);
    final location = ref.watch(effectiveLocationProvider);
    final monthSystem = ref.watch(appSettingsProvider).monthSystem;

    return tithiSvcAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: TithikaColors.shukla,
          strokeWidth: 1.5,
        ),
      ),
      error: (_, _) => Center(
        child: Text(
          'Could not load astronomical data.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: TithikaColors.inkMuted),
        ),
      ),
      data: (tithiSvc) {
        final raw = tithiSvc.calculateForDate(
          localDate: date,
          lat: location.lat,
          lon: location.lon,
          tzOffset: location.tzOffsetAt(date),
        );
        final adjusted = _applyMonthSystem(raw, monthSystem);
        final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
        final data = adjusted.copyWith(festivalName: FestivalDetector.detect(purnimanta));
        return _DayContent(data: data, date: date);
      },
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _DayContent extends ConsumerWidget {
  final DayData data;
  final DateTime date;

  const _DayContent({required this.data, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(effectiveLocationProvider);
    final language = ref.watch(appSettingsProvider).language;
    final isDeva = language == AppLanguage.hindiDevanagari;

    final tz = location.tzOffsetAt(date);
    final isShukla = data.tithi.paksha == Paksha.shukla;
    final pakshaColor =
        isShukla ? TithikaColors.shukla : TithikaColors.krishna;
    final glowColor =
        isShukla ? TithikaColors.shuklaGlow : TithikaColors.krishnaGlow;

    const weekdays = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
    ];
    final weekday = weekdays[date.weekday - 1];

    final tithiWindow =
        '${formatLocalDatetime(data.tithi.start, tz)} – ${formatLocalDatetime(data.tithi.end, tz)}';
    final nakshatraUntil =
        isDeva ? 'तक ${formatLocalTime(data.nakshatra.end, tz)}' : 'until ${formatLocalTime(data.nakshatra.end, tz)}';
    final sunriseStr = data.sunriseUtc != null
        ? formatLocalTime(data.sunriseUtc!, tz)
        : '—';
    final sunsetStr = data.sunsetUtc != null
        ? formatLocalTime(data.sunsetUtc!, tz)
        : '—';

    final baseStyle = Theme.of(context).textTheme.titleLarge;
    final tithiNameStyle = isDeva
        ? devanagariStyle(baseStyle, fontSize: 22)
        : baseStyle?.copyWith(fontSize: 22);
    final tithiFullName =
        isDeva ? data.tithi.fullNameDeva : data.tithi.fullNameEn;
    final lunarMonthLabel = isDeva
        ? '${data.lunarMonth.nameDeva}  ·  ${isShukla ? 'शुक्ल' : 'कृष्ण'} पक्ष'
        : '${data.lunarMonth.nameEn.toUpperCase()}  ·  ${isShukla ? 'SHUKLA' : 'KRISHNA'} PAKSHA';
    final nakshatraLabel = isDeva ? 'नक्षत्र' : 'NAKSHATRA';
    final nakshatraName =
        isDeva ? data.nakshatra.nameDeva : data.nakshatra.nameEn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(
            weekday,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TithikaColors.inkSoft,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  letterSpacing: 0.05 * 13,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${gregorianMonthName(date.month).toUpperCase()} ${date.day}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            lunarMonthLabel,
            style: isDeva
                ? devanagariStyle(
                    Theme.of(context).textTheme.labelSmall,
                    color: pakshaColor,
                    fontSize: 13,
                  )
                : Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: pakshaColor,
                      fontSize: 13,
                      letterSpacing: 0.08 * 12,
                    ),
          ),
          const SizedBox(height: 14),
          MoonPhaseWidget(
            tithiNumber: data.tithi.number,
            glowColor: glowColor,
          ),
          const SizedBox(height: 14),
          Text(tithiFullName, style: tithiNameStyle),
          if (data.festivalName != null) ...[
            const SizedBox(height: 6),
            _FestivalBadge(name: FestivalNames.localize(data.festivalName!, language)!),
          ],
          const SizedBox(height: 6),
          Text(
            tithiWindow,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: TithikaColors.inkSoft, fontSize: 15),
          ),
          if (data.secondaryTithi != null) ...[
            const SizedBox(height: 3),
            Text(
              isDeva
                  ? '· ${data.secondaryTithi!.fullNameDeva} ${formatLocalTime(data.secondaryTithi!.start, tz)} से'
                  : '· ${data.secondaryTithi!.fullNameEn} begins ${formatLocalTime(data.secondaryTithi!.start, tz)}',
              style: isDeva
                  ? devanagariStyle(
                      Theme.of(context).textTheme.bodySmall,
                      color: data.secondaryTithi!.paksha == Paksha.shukla
                          ? TithikaColors.shukla
                          : TithikaColors.krishna,
                      fontSize: 13,
                    )
                  : Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: data.secondaryTithi!.paksha == Paksha.shukla
                            ? TithikaColors.shukla
                            : TithikaColors.krishna,
                        fontSize: 13,
                      ),
            ),
          ],
          const SizedBox(height: 10),
          _DetailCard(
            label: nakshatraLabel,
            value: nakshatraName,
            sub: nakshatraUntil,
            valueStyle: isDeva
                ? devanagariStyle(null,
                    color: TithikaColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)
                : null,
          ),
          const SizedBox(height: 4),
          _SunCard(sunrise: sunriseStr, sunset: sunsetStr),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 16, color: TithikaColors.inkSoft),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  [location.cityName, if (location.country.isNotEmpty) location.country]
                      .join(', '),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TithikaColors.inkSoft,
                        fontSize: 16,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FestivalBadge extends StatelessWidget {
  final String name;

  const _FestivalBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: TithikaColors.festival.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: TithikaColors.festival.withValues(alpha: 0.4)),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: TithikaColors.festival,
              fontSize: 13,
            ),
      ),
    );
  }
}

// ── Detail cards ──────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final TextStyle? valueStyle;

  const _DetailCard({
    required this.label,
    required this.value,
    required this.sub,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValueStyle = valueStyle ??
        const TextStyle(
          color: TithikaColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TithikaColors.card,
        border: Border.all(color: TithikaColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: effectiveValueStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: TithikaColors.inkSoft,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SunCard extends StatelessWidget {
  final String sunrise;
  final String sunset;

  const _SunCard({required this.sunrise, required this.sunset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TithikaColors.card,
        border: Border.all(color: TithikaColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
              child: _SunSegment(
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFFFB347),
                  label: 'SUNRISE',
                  time: sunrise)),
          Container(width: 1, height: 28, color: TithikaColors.line),
          Expanded(
              child: _SunSegment(
                  icon: Icons.nights_stay_rounded,
                  iconColor: TithikaColors.ink,
                  label: 'SUNSET',
                  time: sunset,
                  alignment: CrossAxisAlignment.end)),
        ],
      ),
    );
  }
}

class _SunSegment extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;
  final CrossAxisAlignment alignment;

  const _SunSegment({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isEnd = alignment == CrossAxisAlignment.end;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment:
                isEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            time,
            style: const TextStyle(
              color: TithikaColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4-day strip ───────────────────────────────────────────────────────────────

class _DayStrip extends ConsumerWidget {
  const _DayStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stripAsync = ref.watch(stripDaysProvider);
    final selected = ref.watch(selectedDateProvider);
    final language = ref.watch(appSettingsProvider).language;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: TithikaColors.line)),
        color: Color(0x07FFFFFF),
      ),
      child: stripAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (days) => Row(
          children: List.generate(days.length, (i) {
            final dayData = days[i];
            final cellDate = DateTime(selected.year, selected.month, selected.day)
                .add(Duration(days: i - 1));
            final isSelected = i == 1;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = cellDate;
                },
                child: _StripCell(
                  dayData: dayData,
                  date: cellDate,
                  isSelected: isSelected,
                  language: language,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StripCell extends StatelessWidget {
  final DayData dayData;
  final DateTime date;
  final bool isSelected;
  final AppLanguage language;

  const _StripCell({
    required this.dayData,
    required this.date,
    required this.isSelected,
    required this.language,
  });

  // Named festival takes priority; fall back to recurring observances.
  String? get _label {
    if (dayData.festivalName != null) {
      return FestivalNames.localize(dayData.festivalName, language);
    }
    return switch (dayData.tithi.number) {
      11 || 26 => 'Ekadashi',
      15       => 'Purnima',
      30       => 'Amavasya',
      _        => null,
    };
  }

  Color _labelColor(bool isShukla) {
    if (dayData.festivalName != null) return TithikaColors.festival;
    return switch (dayData.tithi.number) {
      15 => TithikaColors.shukla,
      30 => TithikaColors.krishna,
      _  => TithikaColors.festival,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isShukla = dayData.tithi.paksha == Paksha.shukla;
    final dotColor =
        isShukla ? TithikaColors.shukla : TithikaColors.krishna;

    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final weekday = weekdays[date.weekday - 1];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: const BorderSide(color: TithikaColors.line),
          top: isSelected
              ? const BorderSide(color: TithikaColors.shukla, width: 3)
              : BorderSide.none,
        ),
        color: isSelected
            ? TithikaColors.shuklaGlow.withValues(alpha: 0.08)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: TithikaColors.inkMuted,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected ? TithikaColors.shukla : TithikaColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '${dayData.tithi.pakshaNumber}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: TithikaColors.inkSoft,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
          if (_label != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: _labelColor(isShukla),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Starfield background ──────────────────────────────────────────────────────

