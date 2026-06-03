import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/app_settings.dart';
import '../../models/hora_data.dart';
import '../../state/providers.dart';
import '../shared/page_title_bar.dart';
import '../shared/tithika_nav_bar.dart';
import '../shared/tithika_tab_bar.dart';

class HoraScreen extends ConsumerStatefulWidget {
  const HoraScreen({super.key});

  @override
  ConsumerState<HoraScreen> createState() => _HoraScreenState();
}

class _HoraScreenState extends ConsumerState<HoraScreen> {
  final _scrollController = ScrollController();
  final _currentHoraKey = GlobalKey();
  bool _scrolledToActive = false;

  @override
  void initState() {
    super.initState();
    Future(() {
      final now = DateTime.now();
      ref.read(selectedDateProvider.notifier).state =
          DateTime(now.year, now.month, now.day);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (_scrolledToActive) return;
    _scrolledToActive = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _currentHoraKey.currentContext;
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
    final horaAsync = ref.watch(horaProvider);
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
              title: AppStrings.horaPageTitle(language),
              meta: location.cityName,
            ),
            // Date navigation row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: colors.inkSoft),
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          date.subtract(const Duration(days: 1));
                      setState(() => _scrolledToActive = false);
                    },
                  ),
                  Text(
                    '${AppStrings.weekdayFull(date.weekday, language)},  '
                    '${AppStrings.gregMonth(date.month, language)} ${date.day}',
                    style: scriptStyle(
                      language,
                      Theme.of(context).textTheme.bodyMedium,
                      color: colors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: colors.inkSoft),
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          date.add(const Duration(days: 1));
                      setState(() => _scrolledToActive = false);
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.line),
            Expanded(
              child: horaAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: colors.shukla,
                    strokeWidth: 1.5,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    AppStrings.horaUnavailable(language),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.inkMuted),
                  ),
                ),
                data: (slots) {
                  if (slots == null || slots.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.horaSunriseMissing(language),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.inkMuted),
                      ),
                    );
                  }

                  final now = DateTime.now().toUtc();
                  int activeIdx = -1;
                  for (var i = 0; i < slots.length; i++) {
                    if (!now.isBefore(slots[i].start) &&
                        now.isBefore(slots[i].end)) {
                      activeIdx = i;
                      break;
                    }
                  }

                  final items = _buildItems(slots, activeIdx, tz, language, context);
                  _scrollToCurrent();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (_, i) => items[i],
                  );
                },
              ),
            ),
            const TithikaTabBar(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItems(
    List<HoraSlot> slots,
    int activeIdx,
    Duration tz,
    AppLanguage language,
    BuildContext context,
  ) {
    final now = DateTime.now().toUtc();
    final sunrise = slots.first.start;
    final items = <Widget>[];

    items.add(_HoraSectionHeader(label: AppStrings.horaDay(language)));
    for (var i = 0; i < 12; i++) {
      final slot = slots[i];
      final isActive = i == activeIdx;
      final isPast = now.isAfter(slot.end);
      items.add(_HoraRow(
        key: isActive ? _currentHoraKey : null,
        slot: slot,
        horaNum: i + 1,
        isActive: isActive,
        isPast: isPast,
        tz: tz,
        sunrise: sunrise,
        language: language,
      ));
    }

    items.add(_HoraSectionHeader(label: AppStrings.horaNight(language)));
    for (var i = 12; i < 24; i++) {
      final slot = slots[i];
      final isActive = i == activeIdx;
      final isPast = now.isAfter(slot.end);
      items.add(_HoraRow(
        key: isActive ? _currentHoraKey : null,
        slot: slot,
        horaNum: i - 11,
        isActive: isActive,
        isPast: isPast,
        tz: tz,
        sunrise: sunrise,
        language: language,
      ));
    }

    return items;
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _HoraSectionHeader extends StatelessWidget {
  final String label;
  const _HoraSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
      ),
    );
  }
}

// ── Hora row ──────────────────────────────────────────────────────────────────

class _HoraRow extends StatelessWidget {
  final HoraSlot slot;
  final int horaNum;
  final bool isActive;
  final bool isPast;
  final Duration tz;
  final DateTime sunrise;
  final AppLanguage language;

  const _HoraRow({
    super.key,
    required this.slot,
    required this.horaNum,
    required this.isActive,
    required this.isPast,
    required this.tz,
    required this.sunrise,
    required this.language,
  });

  String _fmt(DateTime utc) {
    final local = utc.add(tz);
    final srLocal = sunrise.add(tz);
    final base = formatLocalTime(utc, tz);
    final isNextDay =
        local.day != srLocal.day || local.month != srLocal.month;
    return isNextDay ? '$base +1' : base;
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final color = slot.planet.accentColor;
    final timeRange = '${_fmt(slot.start)} – ${_fmt(slot.end)}';

    Widget content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.35)
              : colors.line.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Planet circle with glyph
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              slot.planet.glyph,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
          const SizedBox(width: 12),
          // Planet name + sublabel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.planet.name(language),
                  style: scriptStyle(
                    language,
                    null,
                    color: isActive ? color : colors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  AppStrings.horaSubLabel(horaNum, slot.isDay, language),
                  style: scriptStyle(
                    language,
                    null,
                    color: colors.inkSoft,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Time + NOW badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    AppStrings.horaNow(language),
                    style: scriptStyle(
                      language,
                      null,
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                timeRange,
                style: TextStyle(
                  color: isActive ? colors.inkSoft : colors.inkMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isPast && !isActive) {
      content = Opacity(opacity: 0.38, child: content);
    }

    return content;
  }
}
