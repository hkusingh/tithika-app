import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../core/festival_names.dart';
import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../models/lunar_month.dart';
import '../../models/paksha.dart';
import '../../state/providers.dart';
import '../shared/starfield_background.dart';
import '../shared/page_title_bar.dart';
import '../shared/tithika_nav_bar.dart';

const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _monthNamesShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class FestivalsScreen extends ConsumerStatefulWidget {
  const FestivalsScreen({super.key});

  @override
  ConsumerState<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends ConsumerState<FestivalsScreen> {
  final _scrollController = ScrollController();
  final _currentMonthKey = GlobalKey();
  bool _scrolledToMonth = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMonth() {
    if (_scrolledToMonth) return;
    _scrolledToMonth = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _currentMonthKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.0, duration: Duration.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final language = ref.watch(appSettingsProvider).language;
    final now = DateTime.now();
    final year = now.year;
    final currentMonth = now.month;
    final isDecember = currentMonth == 12;

    final festivalsAsync = ref.watch(yearFestivalsProvider(year));
    final nextYearAsync = ref.watch(yearFestivalsProvider(year + 1));

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                TithikaNavBar(),
                Divider(color: colors.line, height: 1),
                PageTitleBar(
                  title: AppStrings.festivalsPageTitle(language),
                  meta: '$year',
                ),

                // ── Body ──────────────────────────────────────────────────
                Expanded(
                  child: festivalsAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(
                          color: colors.shukla, strokeWidth: 1.5),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Could not load festivals.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.inkMuted),
                      ),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            'No festivals found for $year.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.inkMuted),
                          ),
                        );
                      }

                      // Group current year by Gregorian month.
                      final Map<int, List<FestivalEntry>> byMonth = {};
                      for (final e in entries) {
                        byMonth.putIfAbsent(e.date.month, () => []).add(e);
                      }
                      final months = byMonth.keys.toList()..sort();

                      // Build a flat widget list so every item is in the tree
                      // immediately, allowing GlobalKey lookup for scroll-to-month.
                      final items = <Widget>[];
                      for (final m in months) {
                        items.add(_MonthHeader(
                          key: m == currentMonth ? _currentMonthKey : null,
                          month: m,
                        ));
                        for (final entry in byMonth[m]!) {
                          items.add(_FestivalCard(entry: entry));
                        }
                      }

                      // In December, append Jan–Mar of next year.
                      if (isDecember) {
                        final nextEntries = nextYearAsync.valueOrNull ?? [];
                        if (nextEntries.isNotEmpty) {
                          final Map<int, List<FestivalEntry>> nextByMonth = {};
                          for (final e in nextEntries) {
                            if (e.date.month <= 3) {
                              nextByMonth
                                  .putIfAbsent(e.date.month, () => [])
                                  .add(e);
                            }
                          }
                          if (nextByMonth.isNotEmpty) {
                            items.add(_YearHeader(year: year + 1));
                            for (final m in [1, 2, 3]) {
                              if (nextByMonth.containsKey(m)) {
                                items.add(_MonthHeader(month: m));
                                for (final entry in nextByMonth[m]!) {
                                  items.add(_FestivalCard(entry: entry));
                                }
                              }
                            }
                          }
                        }
                      }

                      _scrollToCurrentMonth();

                      return ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 32),
                        children: items,
                      );
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

// ── Year break header ─────────────────────────────────────────────────────────

class _YearHeader extends StatelessWidget {
  final int year;
  const _YearHeader({required this.year});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.line, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$year',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
            ),
          ),
          Expanded(child: Divider(color: colors.line, height: 1)),
        ],
      ),
    );
  }
}

// ── Month section header ──────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final int month;
  const _MonthHeader({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        _monthNames[month - 1],
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: TithikaColors.of(context).shukla,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

// ── Festival card ─────────────────────────────────────────────────────────────

class _FestivalCard extends ConsumerWidget {
  final FestivalEntry entry;
  const _FestivalCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final language = ref.watch(appSettingsProvider).language;
    final date = entry.date;
    final data = entry.data;
    final isShukla = data.tithi.paksha == Paksha.shukla;
    final pakshaColor = isShukla ? colors.shukla : colors.krishna;

    final wd = _weekdays[date.weekday % 7];
    final mo = _monthNamesShort[date.month - 1];
    final gregDate = '$wd, $mo ${date.day}';

    final pakshaLabel = AppStrings.paksha(data.tithi.paksha, language);
    final monthName = switch (language) {
      AppLanguage.hindiDevanagari => data.lunarMonth.nameDeva,
      AppLanguage.tamil           => data.lunarMonth.nameTamil,
      AppLanguage.bengali         => data.lunarMonth.nameBengali,
      _                           => data.lunarMonth.nameEn,
    };
    final hinduDate = '$monthName · $pakshaLabel ${data.tithi.pakshaNumber}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colors.festival.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.festival.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left accent
            Container(
              width: 36,
              height: 56,
              decoration: BoxDecoration(
                color: colors.festival.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Icon(
                Icons.flare_rounded,
                color: colors.festival,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FestivalNames.localize(entry.data.festivalName, language)!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hinduDate,
                      style: scriptStyle(
                        language,
                        Theme.of(context).textTheme.bodySmall,
                        color: pakshaColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Gregorian date
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                gregDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
