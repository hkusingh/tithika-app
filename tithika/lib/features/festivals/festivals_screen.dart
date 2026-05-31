import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../core/festival_names.dart';
import '../../core/theme.dart';
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

/// Maps an English (canonical) festival name to a representative icon.
/// Matching is substring-based on lowercase keywords so variants resolve too.
IconData _festivalIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('holika')) return Icons.local_fire_department_rounded;
  if (n.contains('holi')) return Icons.palette_rounded;
  if (n.contains('gudi padwa') || n.contains('ugadi')) {
    return Icons.celebration_rounded;
  }
  if (n.contains('navratri') || n.contains('navaratri')) {
    return Icons.local_florist_rounded;
  }
  if (n.contains('ram navami')) return Icons.wb_sunny_rounded;
  if (n.contains('hanuman')) return Icons.landscape_rounded;
  if (n.contains('baisakhi') ||
      n.contains('vishu') ||
      n.contains('pongal') ||
      n.contains('sankranti')) {
    return Icons.agriculture_rounded;
  }
  if (n.contains('akshaya')) return Icons.monetization_on_rounded;
  if (n.contains('ganga')) return Icons.water_rounded;
  if (n.contains('hariyali') || n.contains('hartalika')) {
    return Icons.spa_rounded;
  }
  if (n.contains('raksha')) return Icons.favorite_rounded;
  if (n.contains('janmashtami') || n.contains('krishna')) {
    return Icons.music_note_rounded;
  }
  if (n.contains('ganesh')) return Icons.celebration_rounded;
  if (n.contains('diwali') || n.contains('deepavali')) {
    return Icons.light_mode_rounded;
  }
  if (n.contains('dhanteras')) return Icons.savings_rounded;
  if (n.contains('shivaratri') || n.contains('shivratri')) {
    return Icons.nightlight_round;
  }
  if (n.contains('vijayadashami') || n.contains('dashami')) {
    return Icons.shield_rounded;
  }
  if (n.contains('chhath')) return Icons.wb_twilight_rounded;
  if (n.contains('nag panchami')) return Icons.pets_rounded;
  if (n.contains('mahalaya')) return Icons.nights_stay_rounded;
  if (n.contains('jivitputrika')) return Icons.child_care_rounded;
  if (n.contains('karva')) return Icons.bedtime_rounded;
  if (n.contains('ahoi')) return Icons.auto_awesome_rounded;
  if (n.contains('tulsi')) return Icons.eco_rounded;
  if (n.contains('bhai dooj')) return Icons.diversity_1_rounded;
  if (n.contains('govardhan')) return Icons.terrain_rounded;
  if (n.contains('vasant') || n.contains('basant')) {
    return Icons.local_florist_rounded;
  }
  if (n.contains('vat savitri')) return Icons.park_rounded;
  if (n.contains('buddha')) return Icons.self_improvement_rounded;
  if (n.contains('guru')) return Icons.auto_stories_rounded;
  if (n.contains('anant')) return Icons.all_inclusive_rounded;
  if (n.contains('gita')) return Icons.menu_book_rounded;
  if (n.contains('rath yatra')) return Icons.directions_boat_rounded;
  if (n.contains('ekadashi')) return Icons.brightness_3_rounded;
  if (n.contains('purnima')) return Icons.brightness_5_rounded;
  if (n.contains('ashtami') || n.contains('navami')) {
    return Icons.shield_rounded;
  }
  return Icons.celebration_rounded;
}

class FestivalsScreen extends ConsumerStatefulWidget {
  const FestivalsScreen({super.key});

  @override
  ConsumerState<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends ConsumerState<FestivalsScreen> {
  final _scrollController = ScrollController();
  final _currentMonthKey = GlobalKey();
  bool _scrolledToMonth = false;
  bool _showEkadashi = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMonth() {
    if (_scrolledToMonth) return;
    _scrolledToMonth = true;
    // Two post-frame callbacks: the first waits for the ListView to build,
    // the second waits for it to complete layout so off-screen items have
    // valid render objects and Scrollable.ensureVisible can find them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _currentMonthKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, alignment: 0.0, duration: Duration.zero);
        }
      });
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

                // ── Pill toggle ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.line),
                    ),
                    child: Row(
                      children: [
                        _PillTab(
                          label: AppStrings.festivalsPageTitle(language),
                          selected: !_showEkadashi,
                          onTap: () => setState(() {
                            _showEkadashi = false;
                            _scrolledToMonth = false;
                          }),
                        ),
                        _PillTab(
                          label: AppStrings.ekadashi(language),
                          selected: _showEkadashi,
                          onTap: () => setState(() {
                            _showEkadashi = true;
                            _scrolledToMonth = false;
                          }),
                        ),
                      ],
                    ),
                  ),
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
                      final filtered = _showEkadashi
                          ? entries.where((e) => e.isEkadashi).toList()
                          : entries.where((e) => e.inFestivals).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            _showEkadashi
                                ? 'No Ekadashi dates found for $year.'
                                : 'No festivals found for $year.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.inkMuted),
                          ),
                        );
                      }

                      // Group current year by Gregorian month.
                      final byMonth = _groupByMonth(filtered);
                      final months = byMonth.keys.toList()..sort();

                      final items = <Widget>[];
                      for (final m in months) {
                        items.add(_MonthCard(
                          key: m == currentMonth ? _currentMonthKey : null,
                          month: m,
                          entries: byMonth[m]!,
                          showEkadashi: _showEkadashi,
                        ));
                      }

                      // In December, append Jan–Mar of next year.
                      if (isDecember) {
                        final nextAll = nextYearAsync.valueOrNull ?? [];
                        final nextFiltered = _showEkadashi
                            ? nextAll.where((e) => e.isEkadashi).toList()
                            : nextAll.where((e) => e.inFestivals).toList();
                        final nextByMonth = _groupByMonth(nextFiltered
                            .where((e) => e.date.month <= 3)
                            .toList());
                        if (nextByMonth.isNotEmpty) {
                          items.add(_YearHeader(year: year + 1));
                          for (final m in [1, 2, 3]) {
                            if (nextByMonth.containsKey(m)) {
                              items.add(_MonthCard(
                                month: m,
                                entries: nextByMonth[m]!,
                                showEkadashi: _showEkadashi,
                              ));
                            }
                          }
                        }
                      }

                      _scrollToCurrentMonth();

                      return ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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

  Map<int, List<FestivalEntry>> _groupByMonth(List<FestivalEntry> list) {
    final map = <int, List<FestivalEntry>>{};
    for (final e in list) {
      map.putIfAbsent(e.date.month, () => []).add(e);
    }
    return map;
  }
}

// ── Pill toggle tab ───────────────────────────────────────────────────────────

class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected
                ? colors.shukla.withValues(alpha: 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? colors.shukla : colors.inkMuted,
                  fontSize: 13,
                ),
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
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

// ── Month card ────────────────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final int month;
  final List<FestivalEntry> entries;
  final bool showEkadashi;
  const _MonthCard({
    super.key,
    required this.month,
    required this.entries,
    required this.showEkadashi,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final countLabel = showEkadashi
        ? '${entries.length} ${entries.length == 1 ? 'date' : 'dates'}'
        : '${entries.length} ${entries.length == 1 ? 'festival' : 'festivals'}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.ink.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header: month name + count
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthNames[month - 1].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.shukla,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                ),
                Text(
                  countLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.inkMuted,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          if (showEkadashi)
            _EkadashiDateGrid(entries: entries)
          else
            for (int i = 0; i < entries.length; i++)
              _FestivalRow(
                entry: entries[i],
                showDivider: i < entries.length - 1,
              ),
        ],
      ),
    );
  }
}

// ── Festival row (Festivals tab) ──────────────────────────────────────────────

class _FestivalRow extends ConsumerWidget {
  final FestivalEntry entry;
  final bool showDivider;
  const _FestivalRow({required this.entry, required this.showDivider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final language = ref.watch(appSettingsProvider).language;
    final date = entry.date;
    final canonical = entry.data.festivalName ?? 'Ekadashi';
    final name = FestivalNames.localize(canonical, language) ?? canonical;

    final wd = _weekdays[date.weekday % 7];
    final mo = _monthNamesShort[date.month - 1];
    final gregDate = '$wd, $mo ${date.day}';

    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Row(
        children: [
          // Icon chip
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.festival.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _festivalIcon(canonical),
              color: colors.festival,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          // Name (+ Ekadashi tag when applicable)
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: scriptStyle(
                      language,
                      Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                ),
                if (entry.isEkadashi) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.krishna.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppStrings.ekadashi(language),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.krishna,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            gregDate,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.inkSoft,
                  fontSize: 11.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Ekadashi date grid (Ekadasi tab) ──────────────────────────────────────────

class _EkadashiDateGrid extends StatelessWidget {
  final List<FestivalEntry> entries;
  const _EkadashiDateGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final rows = <Widget>[];
    // Two date chips per row.
    for (int i = 0; i < entries.length; i += 2) {
      final second = (i + 1 < entries.length) ? entries[i + 1] : null;
      rows.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 2 : 8),
        child: Row(
          children: [
            Expanded(child: _EkadashiChip(date: entries[i].date, colors: colors)),
            const SizedBox(width: 8),
            Expanded(
              child: second != null
                  ? _EkadashiChip(date: second.date, colors: colors)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _EkadashiChip extends StatelessWidget {
  final DateTime date;
  final TithikaColors colors;
  const _EkadashiChip({required this.date, required this.colors});

  @override
  Widget build(BuildContext context) {
    final wd = _weekdays[date.weekday % 7];
    final mo = _monthNamesShort[date.month - 1];
    final label = '$wd, $mo ${date.day}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.krishna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.krishna.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.brightness_3_rounded, color: colors.krishna, size: 15),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
