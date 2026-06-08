import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/festival_names.dart';
import '../../core/router.dart';
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
import '../festivals/festival_detail_sheet.dart';
import '../shared/starfield_background.dart';
import '../shared/tithika_nav_bar.dart';
import '../shared/tithika_tab_bar.dart';
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
                  flex: 87,
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
                const TithikaTabBar(),
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
    final tithiFullName  = data.tithi.fullName(language);
    final adhikaPrefix   = data.isAdhika ? AppStrings.adhikaPrefix(language) : '';
    final monthBase      = data.lunarMonth.nameFor(language);
    final monthName      = (language == AppLanguage.english || language == AppLanguage.hindiLatin)
        ? monthBase.toUpperCase() : monthBase;
    final lunarMonthLabel =
        '$adhikaPrefix$monthName  ·  ${AppStrings.pakshaUpper(data.tithi.paksha, language)} ${AppStrings.pakshaWord(language)}';
    final nakshatraLabel = AppStrings.nakshatra(language);
    final nakshatraName  = data.nakshatra.nameFor(language);

    return SingleChildScrollView(
      child: Padding(
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              lunarMonthLabel,
              maxLines: 1,
              softWrap: false,
              style: scriptStyle(
                language,
                Theme.of(context).textTheme.labelSmall,
                color: pakshaColor,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 10),
          MoonPhaseWidget(
            tithiNumber: data.tithi.number,
            glowColor: glowColor,
          ),
          const SizedBox(height: 10),
          Text(tithiFullName, style: tithiNameStyle),
          if (data.festivalName != null) ...[
            const SizedBox(height: 6),
            _FestivalBadge(
              name: FestivalNames.localize(data.festivalName!, language)!,
              onTap: () => showFestivalDetail(
                context,
                FestivalEntry(date: date, data: data, isEkadashi: false, inFestivals: true),
              ),
            ),
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
                data.secondaryTithi!.fullName(language),
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
          const SizedBox(height: 6),
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
          GestureDetector(
            onTap: () => context.go(Routes.settings),
            child: Row(
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
                const SizedBox(width: 3),
                Icon(Icons.tune_rounded, size: 13, color: colors.inkMuted),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _FestivalBadge extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _FestivalBadge({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
    final selectedDate = ref.watch(selectedDateProvider);
    if (date.year != selectedDate.year ||
        date.month != selectedDate.month ||
        date.day != selectedDate.day) {
      return const SizedBox.shrink();
    }

    final colors = TithikaColors.of(context);
    final horaAsync = ref.watch(horaProvider);
    final muhurtaAsync = ref.watch(muhurtaProvider);
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

        // ── Rahu warning state ─────────────────────────────────────────────
        _RahuState rahuState = _RahuState.none;
        String rahuText = '';
        String rahuTime = '';

        final muhurta = muhurtaAsync.valueOrNull;
        if (muhurta != null) {
          final rahu = muhurta.rahuKaal;
          final rahuActive = !now.isBefore(rahu.start) && now.isBefore(rahu.end);
          final minsAway = rahu.start.difference(now).inMinutes;
          final approaching = !rahuActive && minsAway >= 0 && minsAway <= 30;

          if (rahuActive) {
            rahuState = _RahuState.active;
            rahuText = '${AppStrings.rahuKaal(language)} — ${AppStrings.avoidNewStarts(language)}';
            rahuTime = 'ends ${formatLocalTime(rahu.end, tz)}';
          } else if (approaching) {
            rahuState = _RahuState.approaching;
            rahuText = '${AppStrings.rahuKaal(language)} in $minsAway min — ${AppStrings.avoidNewStarts(language)}';
            rahuTime = formatLocalTime(rahu.start, tz);
          }
        }

        return GestureDetector(
          onTap: () => context.go('/hora'),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                // ── Rahu warning row ───────────────────────────────────────
                if (rahuState != _RahuState.none)
                  _RahuWarnRow(
                    state: rahuState,
                    text: rahuText,
                    time: rahuTime,
                    colors: colors,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _RahuState { none, approaching, active }

class _RahuWarnRow extends StatelessWidget {
  final _RahuState state;
  final String text;
  final String time;
  final TithikaColors colors;

  const _RahuWarnRow({
    required this.state,
    required this.text,
    required this.time,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final warn = colors.muWarn;
    final icon = state == _RahuState.active
        ? Icons.block_rounded
        : Icons.warning_amber_rounded;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      decoration: BoxDecoration(
        color: warn.withValues(alpha: 0.07),
        border: Border(top: BorderSide(color: warn.withValues(alpha: 0.18))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: warn),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: warn,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: warn,
            ),
          ),
        ],
      ),
    );
  }
}

