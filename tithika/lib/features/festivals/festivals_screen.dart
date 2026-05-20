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

class FestivalsScreen extends ConsumerWidget {
  const FestivalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final festivalsAsync = ref.watch(yearFestivalsProvider(year));

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                TithikaNavBar(title: 'Festivals $year'),
                const Divider(color: TithikaColors.line, height: 1),

                // ── Body ──────────────────────────────────────────────────
                Expanded(
                  child: festivalsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: TithikaColors.shukla, strokeWidth: 1.5),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Could not load festivals.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: TithikaColors.inkMuted),
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
                                ?.copyWith(color: TithikaColors.inkMuted),
                          ),
                        );
                      }

                      // Group by Gregorian month
                      final Map<int, List<FestivalEntry>> byMonth = {};
                      for (final e in entries) {
                        byMonth.putIfAbsent(e.date.month, () => []).add(e);
                      }
                      final months = byMonth.keys.toList()..sort();

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: months.fold<int>(
                          0,
                          (sum, m) => sum + 1 + byMonth[m]!.length,
                        ),
                        itemBuilder: (context, index) {
                          // Flatten months + entries into a single list
                          var remaining = index;
                          for (final m in months) {
                            if (remaining == 0) {
                              return _MonthHeader(month: m);
                            }
                            remaining--;
                            final list = byMonth[m]!;
                            if (remaining < list.length) {
                              return _FestivalCard(entry: list[remaining]);
                            }
                            remaining -= list.length;
                          }
                          return const SizedBox.shrink();
                        },
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

// ── Month section header ──────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final int month;
  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        _monthNames[month - 1],
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: TithikaColors.shukla,
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
    final language = ref.watch(appSettingsProvider).language;
    final date = entry.date;
    final data = entry.data;
    final isShukla = data.tithi.paksha == Paksha.shukla;
    final pakshaColor =
        isShukla ? TithikaColors.shukla : TithikaColors.krishna;

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
          color: TithikaColors.festival.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: TithikaColors.festival.withValues(alpha: 0.18),
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
                color: TithikaColors.festival.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.flare_rounded,
                color: TithikaColors.festival,
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
                            color: TithikaColors.ink,
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
                      color: TithikaColors.inkMuted,
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
