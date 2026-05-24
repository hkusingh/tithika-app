import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/festival_names.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/app_settings.dart';
import '../../models/day_data.dart';
import '../../models/hora_data.dart';
import '../../models/lunar_month.dart';
import '../../models/paksha.dart';
import '../../services/festival_detector.dart';
import '../../services/providers.dart' as svc;
import '../../state/providers.dart';
import '../shared/starfield_background.dart';
import '../shared/tithika_nav_bar.dart';
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
    final colors = TithikaColors.of(context);
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
                TithikaNavBar(
                  centerOverride: !isToday
                      ? GestureDetector(
                          onTap: () {
                            ref.read(selectedDateProvider.notifier).state =
                                today;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.shukla
                                      .withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(20),
                              color: colors.shukla.withValues(alpha: 0.08),
                            ),
                            child: Text(
                              'Today',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.shukla,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                            ),
                          ),
                        )
                      : null,
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
    final colors = TithikaColors.of(context);
    final tithiSvcAsync = ref.watch(svc.tithiServiceProvider);
    final location = ref.watch(effectiveLocationProvider);
    final monthSystem = ref.watch(appSettingsProvider).monthSystem;

    return tithiSvcAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: colors.shukla,
          strokeWidth: 1.5,
        ),
      ),
      error: (_, _) => Center(
        child: Text(
          'Could not load astronomical data.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.inkMuted),
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
    final colors = TithikaColors.of(context);
    final location = ref.watch(effectiveLocationProvider);
    final language = ref.watch(appSettingsProvider).language;

    final tz = location.tzOffsetAt(date);
    final isShukla = data.tithi.paksha == Paksha.shukla;
    final pakshaColor = isShukla ? colors.shukla : colors.krishna;
    final glowColor = isShukla ? colors.shuklaGlow : colors.krishnaGlow;

    final weekday = AppStrings.weekdayFull(date.weekday, language);

    final tithiWindow =
        '${formatLocalDatetime(data.tithi.start, tz)} – ${formatLocalDatetime(data.tithi.end, tz)}';
    final nakshatraUntil = AppStrings.nakshatraUntil(formatLocalTime(data.nakshatra.end, tz), language);
    final sunriseStr = data.sunriseUtc != null ? formatLocalTime(data.sunriseUtc!, tz) : '—';
    final sunsetStr  = data.sunsetUtc  != null ? formatLocalTime(data.sunsetUtc!,  tz) : '—';

    final baseStyle = Theme.of(context).textTheme.titleLarge;
    final tithiNameStyle = scriptStyle(language, baseStyle, fontSize: 22);
    final tithiFullName = switch (language) {
      AppLanguage.hindiDevanagari => data.tithi.fullNameDeva,
      AppLanguage.tamil           => data.tithi.fullNameTamil,
      AppLanguage.bengali         => data.tithi.fullNameBengali,
      _                           => data.tithi.fullNameEn,
    };
    final adhikaPrefix  = data.isAdhika ? AppStrings.adhikaPrefix(language) : '';
    final monthName     = switch (language) {
      AppLanguage.hindiDevanagari => data.lunarMonth.nameDeva,
      AppLanguage.tamil           => data.lunarMonth.nameTamil,
      AppLanguage.bengali         => data.lunarMonth.nameBengali,
      _                           => data.lunarMonth.nameEn.toUpperCase(),
    };
    final lunarMonthLabel =
        '$adhikaPrefix$monthName  ·  ${AppStrings.pakshaUpper(data.tithi.paksha, language)} ${AppStrings.pakshaWord(language)}';
    final nakshatraLabel = AppStrings.nakshatra(language);
    final nakshatraName  = switch (language) {
      AppLanguage.hindiDevanagari => data.nakshatra.nameDeva,
      AppLanguage.tamil           => data.nakshatra.nameTamil,
      AppLanguage.bengali         => data.nakshatra.nameBengali,
      _                           => data.nakshatra.nameEn,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(
            weekday,
            style: scriptStyle(
              language,
              Theme.of(context).textTheme.bodySmall,
              color: colors.inkSoft,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${AppStrings.gregMonth(date.month, language)} ${date.day}, ${date.year}',
            style: scriptStyle(language, Theme.of(context).textTheme.displayLarge, fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            lunarMonthLabel,
            style: scriptStyle(
              language,
              Theme.of(context).textTheme.labelSmall,
              color: pakshaColor,
              fontSize: 15,
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
                ?.copyWith(color: colors.inkSoft, fontSize: 15),
          ),
          if (data.secondaryTithi != null) ...[
            const SizedBox(height: 3),
            Text(
              AppStrings.secondaryTithiBegins(
                switch (language) {
                  AppLanguage.hindiDevanagari => data.secondaryTithi!.fullNameDeva,
                  AppLanguage.tamil           => data.secondaryTithi!.fullNameTamil,
                  AppLanguage.bengali         => data.secondaryTithi!.fullNameBengali,
                  _                           => data.secondaryTithi!.fullNameEn,
                },
                formatLocalTime(data.secondaryTithi!.start, tz),
                language,
              ),
              style: scriptStyle(
                language,
                Theme.of(context).textTheme.bodySmall,
                color: data.secondaryTithi!.paksha == Paksha.shukla
                    ? colors.shukla
                    : colors.krishna,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _DetailCard(
            label: nakshatraLabel,
            value: nakshatraName,
            sub: nakshatraUntil,
            valueStyle: scriptStyle(
              language,
              null,
              color: colors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          _SunCard(
            sunrise: sunriseStr,
            sunset: sunsetStr,
            moonrise: data.moonriseUtc != null ? formatLocalTime(data.moonriseUtc!, tz) : '—',
            moonset:  data.moonsetUtc  != null ? formatLocalTime(data.moonsetUtc!,  tz) : '—',
            language: language,
          ),
          const SizedBox(height: 4),
          _HoraCard(date: date, tz: tz),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 16, color: colors.inkSoft),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  [location.cityName, if (location.country.isNotEmpty) location.country]
                      .join(', '),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.inkSoft,
                        fontSize: 15,
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
    final colors = TithikaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.festival.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.festival.withValues(alpha: 0.4)),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.festival,
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
    final colors = TithikaColors.of(context);
    final effectiveValueStyle = valueStyle ??
        TextStyle(
          color: colors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
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
                style: TextStyle(
                  color: colors.inkSoft,
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
  final String moonrise;
  final String moonset;
  final AppLanguage language;

  const _SunCard({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sun row
          Row(
            children: [
              Expanded(
                  child: _SunSegment(
                      icon: Icons.wb_sunny_rounded,
                      iconColor: const Color(0xFFFFB347),
                      label: AppStrings.sunrise(language),
                      time: sunrise,
                      language: language)),
              Container(width: 1, height: 28, color: colors.line),
              Expanded(
                  child: _SunSegment(
                      icon: Icons.wb_twilight,
                      iconColor: colors.ink,
                      label: AppStrings.sunset(language),
                      time: sunset,
                      alignment: CrossAxisAlignment.end,
                      language: language)),
            ],
          ),
          Divider(height: 1, color: colors.line),
          const SizedBox(height: 4),
          // Moon row
          Row(
            children: [
              Expanded(
                  child: _SunSegment(
                      icon: Icons.brightness_2_rounded,
                      iconColor: colors.inkSoft,
                      label: AppStrings.moonrise(language),
                      time: moonrise,
                      language: language)),
              Container(width: 1, height: 28, color: colors.line),
              Expanded(
                  child: _SunSegment(
                      icon: Icons.brightness_2_outlined,
                      iconColor: colors.inkMuted,
                      label: AppStrings.moonset(language),
                      time: moonset,
                      alignment: CrossAxisAlignment.end,
                      language: language)),
            ],
          ),
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
  final AppLanguage language;

  const _SunSegment({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    required this.language,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
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
                  style: scriptStyle(
                    language,
                    Theme.of(context).textTheme.labelSmall,
                    fontSize: 13,
                  )),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            time,
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hora card ─────────────────────────────────────────────────────────────────

class _HoraCard extends ConsumerWidget {
  final DateTime date;
  final Duration tz;

  const _HoraCard({required this.date, required this.tz});

  String _horaEndTime(DateTime endUtc, DateTime sunriseUtc) {
    final local = endUtc.add(tz);
    final srLocal = sunriseUtc.add(tz);
    final base = formatLocalTime(endUtc, tz);
    final isNextDay =
        local.day != srLocal.day || local.month != srLocal.month;
    return isNextDay ? '$base +1' : base;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show for the currently selected page to avoid stale data.
    final selectedDate = ref.watch(selectedDateProvider);
    if (date.year != selectedDate.year ||
        date.month != selectedDate.month ||
        date.day != selectedDate.day) {
      return const SizedBox.shrink();
    }

    final colors = TithikaColors.of(context);
    final horaAsync = ref.watch(horaProvider);
    final language = ref.watch(appSettingsProvider).language;

    return horaAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (slots) {
        if (slots == null || slots.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now().toUtc();
        int activeIdx = 0;
        for (var i = 0; i < slots.length; i++) {
          if (!now.isBefore(slots[i].start) && now.isBefore(slots[i].end)) {
            activeIdx = i;
            break;
          }
        }
        final active = slots[activeIdx];
        final horaNum = (activeIdx % 12) + 1;
        final color = active.planet.accentColor;
        final endStr = _horaEndTime(active.end, slots.first.start);

        return GestureDetector(
          onTap: () => context.go('/hora'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppStrings.hora(language),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                        border: Border.all(
                            color: color.withValues(alpha: 0.5), width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        active.planet.glyph,
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active.planet.name(language),
                            style: scriptStyle(
                              language,
                              null,
                              color: colors.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            AppStrings.horaSubLabel(
                                horaNum, active.isDay, language),
                            style: scriptStyle(
                              language,
                              null,
                              color: colors.inkMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppStrings.nakshatraUntil(endStr, language),
                      style: TextStyle(
                        color: colors.inkSoft,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: colors.inkMuted),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 4-day strip ───────────────────────────────────────────────────────────────

class _DayStrip extends ConsumerWidget {
  const _DayStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final stripAsync = ref.watch(stripDaysProvider);
    final selected = ref.watch(selectedDateProvider);
    final language = ref.watch(appSettingsProvider).language;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
        color: colors.card,
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
      11 || 26 => AppStrings.ekadashi(language),
      15       => AppStrings.purnima(language),
      30       => AppStrings.amavasya(language),
      _        => null,
    };
  }

  Color _labelColor(TithikaColors colors) {
    if (dayData.festivalName != null) return colors.festival;
    return switch (dayData.tithi.number) {
      15 => colors.shukla,
      30 => colors.krishna,
      _  => colors.festival,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final isShukla = dayData.tithi.paksha == Paksha.shukla;
    final dotColor = isShukla ? colors.shukla : colors.krishna;

    final weekday = AppStrings.weekdayShort(date.weekday, language);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: colors.line),
          top: isSelected
              ? BorderSide(color: colors.shukla, width: 3)
              : BorderSide.none,
        ),
        color: isSelected
            ? colors.shuklaGlow.withValues(alpha: 0.08)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: scriptStyle(
              language,
              Theme.of(context).textTheme.labelSmall,
              color: colors.inkMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected ? colors.shukla : colors.ink,
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
                      color: colors.inkSoft,
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
                      color: _labelColor(colors),
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
