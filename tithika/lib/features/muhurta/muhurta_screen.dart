import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/app_settings.dart';
import '../../models/muhurta_data.dart';
import '../../state/providers.dart';
import '../shared/page_title_bar.dart';
import '../shared/tithika_nav_bar.dart';

class MuhurtaScreen extends ConsumerStatefulWidget {
  const MuhurtaScreen({super.key});

  @override
  ConsumerState<MuhurtaScreen> createState() => _MuhurtaScreenState();
}

class _MuhurtaScreenState extends ConsumerState<MuhurtaScreen> {
  final _scrollController = ScrollController();
  final _activeChogKey = GlobalKey();
  bool _scrolledToActive = false;
  bool _nightExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive() {
    if (_scrolledToActive) return;
    _scrolledToActive = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _activeChogKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.4,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final muhurtaAsync = ref.watch(muhurtaProvider);
    final date = ref.watch(selectedDateProvider);
    final location = ref.watch(effectiveLocationProvider);
    final language = ref.watch(appSettingsProvider).language;
    final tz = location.tzOffsetAt(date);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TithikaNavBar(),
            Divider(color: colors.line, height: 1),
            PageTitleBar(
              title: AppStrings.muhurta(language),
              meta: location.cityName,
            ),
            // Date navigation strip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colors.panel,
                border: Border(
                    bottom: BorderSide(color: colors.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded,
                        color: colors.inkMuted),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          date.subtract(const Duration(days: 1));
                      setState(() {
                        _scrolledToActive = false;
                        _nightExpanded = false;
                      });
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        AppStrings.weekdayFull(date.weekday, language)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08 * 10,
                          color: colors.inkMuted,
                        ),
                      ),
                      Text(
                        '${AppStrings.gregMonth(date.month, language)} ${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        color: colors.inkMuted),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          date.add(const Duration(days: 1));
                      setState(() {
                        _scrolledToActive = false;
                        _nightExpanded = false;
                      });
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: muhurtaAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                      color: colors.shukla, strokeWidth: 1.5),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Could not compute Muhurta.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.inkMuted),
                  ),
                ),
                data: (muhurta) {
                  if (muhurta == null) {
                    return Center(
                      child: Text(
                        'Sunrise data unavailable.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.inkMuted),
                      ),
                    );
                  }
                  _scrollToActive();
                  return _buildContent(
                      context, muhurta, tz, language, date, colors);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MuhurtaData muhurta,
    Duration tz,
    AppLanguage language,
    DateTime date,
    TithikaColors colors,
  ) {
    final now = DateTime.now().toUtc();

    // Find active choghadiya index (for GlobalKey placement).
    int activeDayIdx = -1;
    int activeNightIdx = -1;
    for (var i = 0; i < muhurta.dayChoghadiya.length; i++) {
      final s = muhurta.dayChoghadiya[i];
      if (!now.isBefore(s.start) && now.isBefore(s.end)) {
        activeDayIdx = i;
        break;
      }
    }
    for (var i = 0; i < muhurta.nightChoghadiya.length; i++) {
      final s = muhurta.nightChoghadiya[i];
      if (!now.isBefore(s.start) && now.isBefore(s.end)) {
        activeNightIdx = i;
        break;
      }
    }

    final items = <Widget>[];

    // ── Auspicious section ──────────────────────────────────────────────────
    items.add(_SectionLabel(AppStrings.sectionAuspicious(language)));

    // Brahma Muhurta
    final brahmaPast = now.isAfter(muhurta.brahma.end);
    items.add(_AuspiciousRow(
      icon: '🌅',
      name: AppStrings.brahmaMuhurta(language),
      sub: AppStrings.brahmaMuhurtaSub(language),
      timeRange: _timeRange(muhurta.brahma.start, muhurta.brahma.end, tz),
      isPast: brahmaPast,
    ));

    // Abhijit Muhurta
    final isWednesday = date.weekday == DateTime.wednesday;
    if (isWednesday) {
      items.add(_AuspiciousRow(
        icon: '✦',
        name: AppStrings.abhijitMuhurta(language),
        sub: AppStrings.abhijitNotObserved(language),
        timeRange: '—',
        isPast: false,
        isDimmed: true,
      ));
    } else {
      final abhijit = muhurta.abhijit!;
      final abhijitPast = now.isAfter(abhijit.end);
      items.add(_AuspiciousRow(
        icon: '✦',
        name: AppStrings.abhijitMuhurta(language),
        sub: AppStrings.abhijitMuhurtaSub(language),
        timeRange: _timeRange(abhijit.start, abhijit.end, tz),
        isPast: abhijitPast,
      ));
    }

    // ── Inauspicious section ────────────────────────────────────────────────
    items.add(_SectionLabel(AppStrings.sectionInauspicious(language)));
    items.add(_InauspiciousBlock(
      periods: [
        _InausPeriod(
          name: AppStrings.rahuKaal(language),
          time: _timeRange(
              muhurta.rahuKaal.start, muhurta.rahuKaal.end, tz),
          isActive: !now.isBefore(muhurta.rahuKaal.start) &&
              now.isBefore(muhurta.rahuKaal.end),
          isPast: now.isAfter(muhurta.rahuKaal.end),
        ),
        _InausPeriod(
          name: AppStrings.yamaganda(language),
          time: _timeRange(
              muhurta.yamaganda.start, muhurta.yamaganda.end, tz),
          isActive: !now.isBefore(muhurta.yamaganda.start) &&
              now.isBefore(muhurta.yamaganda.end),
          isPast: now.isAfter(muhurta.yamaganda.end),
        ),
        _InausPeriod(
          name: AppStrings.gulika(language),
          time: _timeRange(
              muhurta.gulika.start, muhurta.gulika.end, tz),
          isActive: !now.isBefore(muhurta.gulika.start) &&
              now.isBefore(muhurta.gulika.end),
          isPast: now.isAfter(muhurta.gulika.end),
        ),
      ],
      language: language,
    ));

    // ── Day Choghadiya ──────────────────────────────────────────────────────
    items.add(_SectionLabel(AppStrings.dayChoghadiya(language)));
    items.add(_ChoghadiyaBlock(
      slots: muhurta.dayChoghadiya,
      activeIdx: activeDayIdx,
      activeKey: activeNightIdx == -1 ? _activeChogKey : null,
      tz: tz,
      language: language,
    ));

    // ── Night Choghadiya ────────────────────────────────────────────────────
    items.add(_NightChoghadiyaSection(
      slots: muhurta.nightChoghadiya,
      expanded: _nightExpanded,
      activeIdx: activeNightIdx,
      activeKey: activeNightIdx != -1 ? _activeChogKey : null,
      tz: tz,
      language: language,
      onToggle: () => setState(() => _nightExpanded = !_nightExpanded),
    ));

    items.add(const SizedBox(height: 24));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  String _timeRange(DateTime start, DateTime end, Duration tz) =>
      '${formatLocalTime(start, tz)}–${formatLocalTime(end, tz)}';
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 5),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10 * 9,
          color: colors.inkMuted,
        ),
      ),
    );
  }
}

// ── Auspicious row ────────────────────────────────────────────────────────────

class _AuspiciousRow extends StatelessWidget {
  final String icon;
  final String name;
  final String sub;
  final String timeRange;
  final bool isPast;
  final bool isDimmed;

  const _AuspiciousRow({
    required this.icon,
    required this.name,
    required this.sub,
    required this.timeRange,
    required this.isPast,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final opacity = isPast ? 0.38 : (isDimmed ? 0.45 : 1.0);
    final accentColor = isDimmed ? colors.inkMuted : colors.shukla;
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 8, 10, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      icon,
                      style: TextStyle(fontSize: 15, color: accentColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDimmed ? colors.inkMuted : colors.ink,
                          ),
                        ),
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.inkMuted,
                            fontStyle:
                                isDimmed ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeRange,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDimmed ? colors.inkMuted : colors.inkSoft,
                      fontStyle:
                          isDimmed ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inauspicious block ────────────────────────────────────────────────────────

class _InausPeriod {
  final String name;
  final String time;
  final bool isActive;
  final bool isPast;

  const _InausPeriod({
    required this.name,
    required this.time,
    required this.isActive,
    required this.isPast,
  });
}

class _InauspiciousBlock extends StatelessWidget {
  final List<_InausPeriod> periods;
  final AppLanguage language;

  const _InauspiciousBlock(
      {required this.periods, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < periods.length; i++)
            _InausRow(
              period: periods[i],
              isLast: i == periods.length - 1,
              language: language,
            ),
        ],
      ),
    );
  }
}

class _InausRow extends StatelessWidget {
  final _InausPeriod period;
  final bool isLast;
  final AppLanguage language;

  const _InausRow(
      {required this.period, required this.isLast, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Opacity(
      opacity: period.isPast ? 0.38 : 1.0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: period.isActive
              ? colors.muWarn.withValues(alpha: 0.06)
              : null,
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                '⚠',
                style:
                    TextStyle(fontSize: 14, color: colors.muWarn),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                period.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      period.isActive ? colors.muWarn : colors.ink,
                ),
              ),
            ),
            if (period.isActive) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.muWarn,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  AppStrings.labelNow(language),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              period.time,
              style: TextStyle(
                fontSize: 10,
                fontWeight: period.isActive ? FontWeight.w600 : FontWeight.normal,
                color: period.isActive ? colors.muWarn : colors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Choghadiya block (day or night) ──────────────────────────────────────────

class _ChoghadiyaBlock extends StatelessWidget {
  final List<ChoghadiyaSlot> slots;
  final int activeIdx;
  final GlobalKey? activeKey;
  final Duration tz;
  final AppLanguage language;

  const _ChoghadiyaBlock({
    required this.slots,
    required this.activeIdx,
    required this.activeKey,
    required this.tz,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < slots.length; i++)
            _ChogRow(
              key: i == activeIdx ? activeKey : null,
              slot: slots[i],
              isActive: i == activeIdx,
              isLast: i == slots.length - 1,
              tz: tz,
              language: language,
            ),
        ],
      ),
    );
  }
}

class _ChogRow extends StatelessWidget {
  final ChoghadiyaSlot slot;
  final bool isActive;
  final bool isLast;
  final Duration tz;
  final AppLanguage language;

  const _ChogRow({
    super.key,
    required this.slot,
    required this.isActive,
    required this.isLast,
    required this.tz,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final now = DateTime.now().toUtc();
    final isPast = now.isAfter(slot.end);
    final isWarn = isActive && slot.type.isInauspicious;

    Color activeBg;
    if (isActive) {
      activeBg = isWarn
          ? colors.muWarn.withValues(alpha: 0.08)
          : colors.shukla.withValues(alpha: 0.08);
    } else {
      activeBg = Colors.transparent;
    }

    return Opacity(
      opacity: isPast ? 0.38 : 1.0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: activeBg,
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: slot.type.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Text(
                    AppStrings.choghadiyaName(slot.type, language),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? (isWarn ? colors.muWarn : colors.shukla)
                          : colors.ink,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isWarn ? colors.muWarn : colors.shukla,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        AppStrings.labelNow(language),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              AppStrings.choghadiyaQuality(slot.type, language),
              style: TextStyle(fontSize: 9, color: colors.inkMuted),
            ),
            const SizedBox(width: 8),
            Text(
              isActive
                  ? 'until ${formatLocalTime(slot.end, tz)}'
                  : '${formatLocalTime(slot.start, tz)}–${formatLocalTime(slot.end, tz)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? (isWarn ? colors.muWarn : colors.shukla)
                    : colors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Night Choghadiya section ──────────────────────────────────────────────────

class _NightChoghadiyaSection extends StatelessWidget {
  final List<ChoghadiyaSlot> slots;
  final bool expanded;
  final int activeIdx;
  final GlobalKey? activeKey;
  final Duration tz;
  final AppLanguage language;
  final VoidCallback onToggle;

  const _NightChoghadiyaSection({
    required this.slots,
    required this.expanded,
    required this.activeIdx,
    required this.activeKey,
    required this.tz,
    required this.language,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final startStr =
        slots.isNotEmpty ? formatLocalTime(slots.first.start, tz) : '—';
    final endStr =
        slots.isNotEmpty ? formatLocalTime(slots.last.end, tz) : '—';

    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border.all(color: colors.line),
              borderRadius: expanded
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('🌙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.nightChoghadiya(language),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        '${slots.length} slots · $startStr – $endStr',
                        style: TextStyle(
                            fontSize: 10, color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  expanded
                      ? AppStrings.nightChoghadiyaCollapse(language)
                      : AppStrings.nightChoghadiyaExpand(language),
                  style:
                      TextStyle(fontSize: 11, color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border(
                left: BorderSide(color: colors.line),
                right: BorderSide(color: colors.line),
                bottom: BorderSide(color: colors.line),
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < slots.length; i++)
                  _ChogRow(
                    key: i == activeIdx ? activeKey : null,
                    slot: slots[i],
                    isActive: i == activeIdx,
                    isLast: i == slots.length - 1,
                    tz: tz,
                    language: language,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
