import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/day_data.dart';
import '../../models/lunar_month.dart';
import '../../models/paksha.dart';
import '../../state/providers.dart';
import '../shared/starfield_background.dart';

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
    final month = ref.watch(selectedMonthProvider);
    final monthAsync = ref.watch(monthDataProvider((month.year, month.month)));

    final gregorianLabel = '${gregorianMonthName(month.month)} ${month.year}';

    // Collect all distinct Hindu months in first-appearance order.
    // Adhika and Nija of the same month are tracked separately.
    final hinduMonthNames = <String>[];
    ({LunarMonth? month, bool isAdhika}) lastSeen = (month: null, isAdhika: false);
    for (final data in (monthAsync.valueOrNull?.values ?? const <DayData>[])) {
      if (data.lunarMonth != lastSeen.month || data.isAdhika != lastSeen.isAdhika) {
        final base = data.lunarMonth.nameEn.toUpperCase();
        hinduMonthNames.add(data.isAdhika ? 'ADH. $base' : base);
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
                // ── Month header (fixed) ──────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: TithikaColors.inkSoft),
                        onPressed: _goToPrevMonth,
                      ),
                      Column(
                        children: [
                          Text(
                            gregorianLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 16),
                          ),
                          if (hinduMonthLabel.isNotEmpty)
                            Text(
                              hinduMonthLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: TithikaColors.shukla,
                                    letterSpacing: 0.06 * 11,
                                  ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded,
                            color: TithikaColors.inkSoft),
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                ),

                // ── Back to Day View (fixed) ──────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: TithikaColors.inkSoft),
                    label: Text(
                      'Day View',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),

                // ── Weekday header (fixed) ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style:
                                    Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(color: TithikaColors.line, height: 1),

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
    final monthAsync = ref.watch(monthDataProvider((year, month)));

    return monthAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: TithikaColors.shukla, strokeWidth: 1.5),
      ),
      error: (e, _) => Center(
        child: Text(
          'Could not load month data.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: TithikaColors.inkMuted),
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
    final isFestival = data?.festivalName != null;
    final isShukla = data?.tithi.paksha == Paksha.shukla;
    final dotColor = data == null
        ? TithikaColors.inkMuted
        : (isShukla ? TithikaColors.shukla : TithikaColors.krishna);

    final isHinduMonthStart = hinduMonthLabel != null;

    Color? bgColor;
    if (isSelected) {
      bgColor = TithikaColors.shukla.withValues(alpha: 0.20);
    } else if (isToday) {
      bgColor = TithikaColors.shukla.withValues(alpha: 0.14);
    } else if (isFestival) {
      bgColor = TithikaColors.festival.withValues(alpha: 0.08);
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: isSelected
              ? const BorderSide(color: TithikaColors.shukla, width: 2)
              : isHinduMonthStart
                  ? BorderSide(
                      color: TithikaColors.shukla.withValues(alpha: 0.5),
                      width: 1.5)
                  : BorderSide.none,
          bottom: const BorderSide(color: Color(0x0AFFFFFF)),
          right: const BorderSide(color: Color(0x0AFFFFFF)),
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
                style: const TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: TithikaColors.shukla,
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
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    color: TithikaColors.shukla,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? TithikaColors.shukla
                    : isToday
                        ? TithikaColors.moonDark
                        : TithikaColors.ink,
              ),
            ),
          ),

          // Paksha dot
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),

          // Tithi number
          if (data != null)
            Text(
              '${data!.tithi.pakshaNumber}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isShukla ? TithikaColors.shukla : TithikaColors.krishna,
              ),
            ),

          // Festival dot
          if (isFestival)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: TithikaColors.festival,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Month festival list ───────────────────────────────────────────────────────

class _MonthFestivalList extends StatelessWidget {
  final int year;
  final int month;
  final Map<int, DayData> monthData;

  const _MonthFestivalList({
    required this.year,
    required this.month,
    required this.monthData,
  });

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final festivals = <({int day, String name})>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      final name = monthData[d]?.festivalName;
      if (name != null) festivals.add((day: d, name: name));
    }

    if (festivals.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: TithikaColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              'FESTIVALS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TithikaColors.shukla,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
            ),
          ),
          const Divider(height: 1, color: TithikaColors.line),
          ...festivals.map((f) {
            final date = DateTime(year, month, f.day);
            final wd = _weekdays[date.weekday % 7];
            final mo = _months[month - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    child: Text(
                      '$wd ${f.day} $mo',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: TithikaColors.inkSoft,
                            fontSize: 10,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 3, height: 3,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: TithikaColors.festival)),
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
    final transitionsAsync =
        ref.watch(hinduMonthTransitionsProvider((year, month)));

    return transitionsAsync.when(
      loading: () => const SizedBox(height: 28),
      error: (_, __) => const SizedBox.shrink(),
      data: (transitions) {
        if (transitions.isEmpty) return const SizedBox.shrink();
        const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: transitions.map((info) {
              final wd = weekdays[info.date.weekday % 7];
              final mo = months[info.date.month - 1];
              final time = formatLocalTime(info.startUtc, info.tzOffset);
              return Text(
                '${info.month.nameEn} begins $wd, $mo ${info.date.day} at $time',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TithikaColors.inkSoft,
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
