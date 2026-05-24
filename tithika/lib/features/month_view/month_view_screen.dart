import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/festival_names.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/app_settings.dart';
import '../../models/day_data.dart';
import '../../models/lunar_month.dart';
import '../../models/paksha.dart';
import '../../state/providers.dart';
import '../day_view/moon_phase_widget.dart';
import '../shared/starfield_background.dart';
import '../shared/tithika_nav_bar.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class MonthViewScreen extends ConsumerStatefulWidget {
  const MonthViewScreen({super.key});

  @override
  ConsumerState<MonthViewScreen> createState() => _MonthViewScreenState();
}

class _MonthViewScreenState extends ConsumerState<MonthViewScreen> {
  late PageController _pageController;

  static int _toPage(DateTime m) => m.year * 12 + (m.month - 1);
  static DateTime _fromPage(int p) => DateTime(p ~/ 12, p % 12 + 1);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _toPage(ref.read(selectedMonthProvider)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevMonth() {
    _pageController.animateToPage(
      _pageController.page!.round() - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextMonth() {
    _pageController.animateToPage(
      _pageController.page!.round() + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final month = ref.watch(selectedMonthProvider);
    final monthAsync = ref.watch(monthDataProvider((month.year, month.month)));

    final gregorianLabel = '${gregorianMonthName(month.month)} ${month.year}';
    final language = ref.watch(appSettingsProvider).language;
    // Collect all distinct Hindu months in first-appearance order.
    // Adhika and Nija of the same month are tracked separately.
    final hinduMonthNames = <String>[];
    ({LunarMonth? month, bool isAdhika}) lastSeen = (month: null, isAdhika: false);
    for (final data in (monthAsync.valueOrNull?.values ?? const <DayData>[])) {
      if (data.lunarMonth != lastSeen.month || data.isAdhika != lastSeen.isAdhika) {
        final base = switch (language) {
          AppLanguage.hindiDevanagari => data.lunarMonth.nameDeva,
          AppLanguage.tamil           => data.lunarMonth.nameTamil,
          AppLanguage.bengali         => data.lunarMonth.nameBengali,
          _                           => data.lunarMonth.nameEn.toUpperCase(),
        };
        hinduMonthNames.add(
          data.isAdhika ? '${AppStrings.adhikaPrefixShort(language)}$base' : base,
        );
        lastSeen = (month: data.lunarMonth, isAdhika: data.isAdhika);
      }
    }
    final hinduMonthLabel = hinduMonthNames.join(' – ');

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── Shared nav bar (no title — month shown in strip below) ──
                const TithikaNavBar(),
                Divider(color: colors.line, height: 1),

                // ── Month navigation strip ────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded,
                            color: colors.inkSoft),
                        onPressed: _goToPrevMonth,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              gregorianLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink,
                                    fontSize: 14,
                                  ),
                            ),
                            if (hinduMonthLabel.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  hinduMonthLabel,
                                  style: scriptStyle(
                                    language,
                                    Theme.of(context).textTheme.labelSmall,
                                    color: colors.shukla,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded,
                            color: colors.inkSoft),
                        onPressed: _goToNextMonth,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),

                // ── Weekday header (fixed) ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: List.generate(7, (i) => AppStrings.weekdayLetter(i, language))
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: scriptStyle(
                                  language,
                                  Theme.of(context).textTheme.labelSmall,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Divider(color: colors.line, height: 1),

                // ── Swipable grid ─────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      ref.read(selectedMonthProvider.notifier).state =
                          _fromPage(index);
                    },
                    itemBuilder: (context, index) {
                      final m = _fromPage(index);
                      return _MonthPage(year: m.year, month: m.month);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month page (one page of the PageView) ─────────────────────────────────────

class _MonthPage extends ConsumerWidget {
  final int year;
  final int month;

  const _MonthPage({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final monthAsync = ref.watch(monthDataProvider((year, month)));

    return monthAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
            color: colors.shukla, strokeWidth: 1.5),
      ),
      error: (e, _) => Center(
        child: Text(
          'Could not load month data.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.inkMuted),
        ),
      ),
      data: (monthData) => LayoutBuilder(
        builder: (context, constraints) {
          // Compute the grid's natural height from row count so it never
          // shrinks when the festival list is long.
          final firstWeekday = DateTime(year, month, 1).weekday % 7;
          final daysInMonth = DateTime(year, month + 1, 0).day;
          final rows = ((firstWeekday + daysInMonth) / 7).ceil();
          // Grid has horizontal padding 6 each side; childAspectRatio 0.72.
          final cellWidth = (constraints.maxWidth - 12) / 7;
          final gridHeight = rows * cellWidth / 0.72 + 8;

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: gridHeight,
                  child: _MonthGrid(
                    year: year,
                    month: month,
                    monthData: monthData,
                  ),
                ),
                _NextHinduMonthNote(year: year, month: month),
                _MonthFestivalList(year: year, month: month, monthData: monthData),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Month grid ────────────────────────────────────────────────────────────────

class _MonthGrid extends ConsumerWidget {
  final int year;
  final int month;
  final Map<int, DayData> monthData;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.monthData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final today = DateTime.now();

    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    // Precompute which days start a new Hindu month within this grid.
    // Tracks both lunarMonth and isAdhika so Adhika + Nija of the same month
    // each get their own label entry.
    final Map<int, String> monthLabels = {};
    LunarMonth? lastLunarMonth;
    bool lastIsAdhika = false;
    for (var d = 1; d <= daysInMonth; d++) {
      final data = monthData[d];
      if (data != null &&
          (data.lunarMonth != lastLunarMonth ||
              data.isAdhika != lastIsAdhika)) {
        final abbr = data.lunarMonth.abbr4;
        monthLabels[d] = data.isAdhika ? 'A.${abbr.substring(0, 3)}' : abbr;
        lastLunarMonth = data.lunarMonth;
        lastIsAdhika = data.isAdhika;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.72,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final day = index - firstWeekday + 1;
          if (day < 1 || day > daysInMonth) return const SizedBox();

          final data = monthData[day];
          final cellDate = DateTime(year, month, day);
          final isToday = cellDate.year == today.year &&
              cellDate.month == today.month &&
              cellDate.day == today.day;
          final isSelected = cellDate.year == selected.year &&
              cellDate.month == selected.month &&
              cellDate.day == selected.day;

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = cellDate;
              context.go('/');
            },
            child: _MonthCell(
              day: day,
              data: data,
              isToday: isToday,
              isSelected: isSelected,
              hinduMonthLabel: monthLabels[day],
            ),
          );
        },
      ),
    );
  }
}

// ── Month cell ────────────────────────────────────────────────────────────────

class _MonthCell extends StatelessWidget {
  final int day;
  final DayData? data;
  final bool isToday;
  final bool isSelected;
  final String? hinduMonthLabel;

  const _MonthCell({
    required this.day,
    required this.data,
    required this.isToday,
    required this.isSelected,
    this.hinduMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final isFestival = data?.festivalName != null;
    final isShukla = data?.tithi.paksha == Paksha.shukla;
    final isHinduMonthStart = hinduMonthLabel != null;

    Color? bgColor;
    if (isSelected) {
      bgColor = colors.shukla.withValues(alpha: 0.20);
    } else if (isToday) {
      bgColor = colors.shukla.withValues(alpha: 0.14);
    } else if (isFestival) {
      bgColor = colors.festival.withValues(alpha: 0.08);
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: isSelected
              ? BorderSide(color: colors.shukla, width: 2)
              : isHinduMonthStart
                  ? BorderSide(
                      color: colors.shukla.withValues(alpha: 0.5),
                      width: 1.5)
                  : BorderSide.none,
          bottom: BorderSide(color: colors.line),
          right: BorderSide(color: colors.line),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hindu month label — bold gold on first day of new lunar month
          if (isHinduMonthStart)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hinduMonthLabel!,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: colors.shukla,
                  letterSpacing: 0.3,
                ),
              ),
            )
          else
            const SizedBox(height: 4),

          // Date number
          Container(
            width: 20,
            height: 20,
            decoration: (isToday && !isSelected)
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.shukla,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colors.shukla
                    : isToday
                        ? colors.moonDark
                        : colors.ink,
              ),
            ),
          ),

          // Moon phase icon
          if (data != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: MoonPhaseWidget(
                tithiNumber: data!.tithi.number,
                glowColor: Colors.transparent,
                size: 14,
              ),
            )
          else
            const SizedBox(height: 16),

          // Tithi number
          if (data != null)
            Text(
              '${data!.tithi.pakshaNumber}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isShukla ? colors.shukla : colors.krishna,
              ),
            ),

          // Festival dot
          if (isFestival)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.festival,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Month festival list ───────────────────────────────────────────────────────

class _MonthFestivalList extends ConsumerWidget {
  final int year;
  final int month;
  final Map<int, DayData> monthData;

  const _MonthFestivalList({
    required this.year,
    required this.month,
    required this.monthData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final language = ref.watch(appSettingsProvider).language;
    final festivals = <({int day, String name})>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      final key = monthData[d]?.festivalName;
      if (key != null) festivals.add((day: d, name: FestivalNames.localize(key, language)!));
    }

    if (festivals.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              AppStrings.festivals(language),
              style: scriptStyle(
                language,
                Theme.of(context).textTheme.labelSmall,
                color: colors.shukla,
                fontSize: 10,
              ),
            ),
          ),
          Divider(height: 1, color: colors.line),
          ...festivals.map((f) {
            final date = DateTime(year, month, f.day);
            final wd = AppStrings.weekdayShort(date.weekday, language);
            final mo = AppStrings.gregMonthShort(month, language);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    child: Text(
                      '$wd ${f.day} $mo',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.inkSoft,
                            fontSize: 10,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.festival,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Next Hindu month note ─────────────────────────────────────────────────────

class _NextHinduMonthNote extends ConsumerWidget {
  final int year;
  final int month;

  const _NextHinduMonthNote({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final transitionsAsync =
        ref.watch(hinduMonthTransitionsProvider((year, month)));
    final language = ref.watch(appSettingsProvider).language;

    return transitionsAsync.when(
      loading: () => const SizedBox(height: 28),
      error: (e, s) => const SizedBox.shrink(),
      data: (transitions) {
        if (transitions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: transitions.map((info) {
              final wd   = AppStrings.weekdayShort(info.date.weekday, language);
              final mo   = AppStrings.gregMonthShort(info.date.month, language);
              final time = formatLocalTime(info.startUtc, info.tzOffset);
              final monthName = switch (language) {
                AppLanguage.hindiDevanagari => info.month.nameDeva,
                AppLanguage.tamil           => info.month.nameTamil,
                AppLanguage.bengali         => info.month.nameBengali,
                _                           => info.month.nameEn,
              };
              return Text(
                AppStrings.hinduMonthBegins(monthName, wd, mo, info.date.day, time, language),
                style: scriptStyle(
                  language,
                  Theme.of(context).textTheme.bodySmall,
                  color: colors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
