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

class MonthViewScreen extends ConsumerWidget {
  const MonthViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final monthAsync =
        ref.watch(monthDataProvider((month.year, month.month)));

    final gregorianLabel =
        '${gregorianMonthName(month.month)} ${month.year}';

    // Use day-1's lunarMonth for the header subtitle when data is ready.
    final hinduMonthLabel = monthAsync.valueOrNull?[1]?.lunarMonth.nameEn
            .toUpperCase() ??
        '';

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                // Month header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: TithikaColors.inkSoft),
                        onPressed: () {
                          ref.read(selectedMonthProvider.notifier).state =
                              DateTime(month.year, month.month - 1);
                        },
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
                        onPressed: () {
                          ref.read(selectedMonthProvider.notifier).state =
                              DateTime(month.year, month.month + 1);
                        },
                      ),
                    ],
                  ),
                ),

                // Back to Day View
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

                // Weekday header
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

                // Grid
                Expanded(
                  child: monthAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: TithikaColors.shukla,
                        strokeWidth: 1.5,
                      ),
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
                    data: (monthData) => _MonthGrid(
                      year: month.year,
                      month: month.month,
                      monthData: monthData,
                    ),
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

    // weekday of the 1st: DateTime.weekday is Mon=1…Sun=7; grid is Sun-first.
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    // Precompute which days start a new Hindu month within this grid.
    final Map<int, String> monthLabels = {};
    LunarMonth? lastLunarMonth;
    for (var d = 1; d <= daysInMonth; d++) {
      final data = monthData[d];
      if (data != null && data.lunarMonth != lastLunarMonth) {
        monthLabels[d] = data.lunarMonth.abbr4;
        lastLunarMonth = data.lunarMonth;
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

    // Today and selected can overlap; selected takes visual priority.
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
              : BorderSide.none,
          bottom: const BorderSide(color: Color(0x0AFFFFFF)),
          right: const BorderSide(color: Color(0x0AFFFFFF)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hindu month label — only on first day of a new lunar month
          if (hinduMonthLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hinduMonthLabel!,
                style: const TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                  color: TithikaColors.inkMuted,
                  letterSpacing: 0.3,
                ),
              ),
            )
          else
            const SizedBox(height: 4),

          // Date number — gold circle for today, gold text for selected
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
                color: isShukla
                    ? TithikaColors.shukla
                    : TithikaColors.krishna,
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

// ── Starfield background ──────────────────────────────────────────────────────

