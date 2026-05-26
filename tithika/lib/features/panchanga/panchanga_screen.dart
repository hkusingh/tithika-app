import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/app_settings.dart';
import '../../models/day_data.dart';
import '../../models/pancha_data.dart';
import '../../state/providers.dart';
import '../shared/page_title_bar.dart';
import '../shared/starfield_background.dart';
import '../shared/tithika_nav_bar.dart';

class PanchaScreen extends ConsumerStatefulWidget {
  const PanchaScreen({super.key});

  @override
  ConsumerState<PanchaScreen> createState() => _PanchaScreenState();
}

class _PanchaScreenState extends ConsumerState<PanchaScreen> {
  final _scrollController = ScrollController();
  final _currentKaranaKey = GlobalKey();
  bool _scrolledToActive = false;

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
      final ctx = _currentKaranaKey.currentContext;
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
    final panchaAsync = ref.watch(panchaProvider);
    final dayDataAsync = ref.watch(dayDataProvider);
    final date = ref.watch(selectedDateProvider);
    final location = ref.watch(effectiveLocationProvider);
    final language = ref.watch(appSettingsProvider).language;
    final tz = location.tzOffsetAt(date);

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                TithikaNavBar(),
                Divider(color: colors.line, height: 1),
                PageTitleBar(
                  title: AppStrings.panchaTitle(language),
                  meta: location.cityName,
                ),
                // Date navigation
                _DateNav(date: date, onChanged: (d) {
                  ref.read(selectedDateProvider.notifier).state = d;
                  setState(() => _scrolledToActive = false);
                }),
                // Content
                Expanded(
                  child: panchaAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: colors.shukla,
                        strokeWidth: 1.5,
                      ),
                    ),
                    error: (_, _) => Center(
                      child: Text(
                        'Panchanga unavailable for this date.',
                        style: TextStyle(color: colors.inkMuted),
                      ),
                    ),
                    data: (pancha) {
                      if (pancha == null) {
                        return Center(
                          child: Text(
                            'Panchanga unavailable — sunrise data missing.',
                            style: TextStyle(color: colors.inkMuted),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      final dayData = dayDataAsync.valueOrNull;
                      _scrollToCurrent();
                      return ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                        children: [
                          // ── Five Elements summary ─────────────────────────
                          if (dayData != null) ...[
                            _SectionLabel(AppStrings.fiveElementsLabel(language)),
                            const SizedBox(height: 6),
                            _FiveElementsCard(
                              dayData: dayData,
                              pancha: pancha,
                              tz: tz,
                              language: language,
                              date: date,
                            ),
                            const SizedBox(height: 16),
                          ],
                          // ── Yoga section ─────────────────────────────────
                          _SectionLabel(AppStrings.yogaLabel(language)),
                          const SizedBox(height: 6),
                          _YogaCard(
                            yoga: pancha.currentYoga,
                            nextYoga: pancha.nextYoga,
                            tz: tz,
                            language: language,
                          ),
                          const SizedBox(height: 16),
                          // ── Karana section ───────────────────────────────
                          _SectionLabel(AppStrings.karanaLabel(language)),
                          const SizedBox(height: 6),
                          _KaranaList(
                            karanas: pancha.karanas,
                            tz: tz,
                            language: language,
                            currentKey: _currentKaranaKey,
                          ),
                        ],
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

// ── Date navigation ───────────────────────────────────────────────────────────

class _DateNav extends ConsumerWidget {
  final DateTime date;
  final void Function(DateTime) onChanged;

  const _DateNav({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final language = ref.watch(appSettingsProvider).language;

    final dow = AppStrings.weekdayFull(date.weekday, language);
    final mon = AppStrings.gregMonth(date.month, language);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: colors.inkSoft),
            onPressed: () => onChanged(date.subtract(const Duration(days: 1))),
          ),
          Column(
            children: [
              Text(
                dow,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08 * 10,
                  color: colors.inkMuted,
                ),
              ),
              Text(
                '$mon ${date.day}, ${date.year}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: colors.inkSoft),
            onPressed: () => onChanged(date.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1 * 9,
        color: colors.inkMuted,
      ),
    );
  }
}

// ── Yoga card ─────────────────────────────────────────────────────────────────

class _YogaCard extends StatelessWidget {
  final YogaInfo yoga;
  final YogaInfo nextYoga;
  final Duration tz;
  final AppLanguage language;

  const _YogaCard({
    required this.yoga,
    required this.nextYoga,
    required this.tz,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final now = DateTime.now().toUtc();
    final quality = yoga.quality;
    final qColor = quality.color;

    // Progress through current yoga (0.0–1.0)
    final totalMs = yoga.end.difference(yoga.start).inMilliseconds;
    final elapsedMs = now.difference(yoga.start).inMilliseconds;
    final progress = (elapsedMs / totalMs).clamp(0.0, 1.0);

    final startStr = formatLocalTime(yoga.start, tz);
    final endStr   = formatLocalTime(yoga.end, tz);
    final name     = AppStrings.yogaName(yoga.number, language);
    final nextName = AppStrings.yogaName(nextYoga.number, language);
    final nextStart = formatLocalTime(nextYoga.start, tz);
    final qualityLabel = AppStrings.yogaQualityLabel(quality, language);
    final nextQColor = nextYoga.quality.color;

    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Current yoga ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '$startStr – $endStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Quality badge
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: qColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      qualityLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: qColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).round()}% elapsed',
                      style: TextStyle(fontSize: 10, color: colors.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colors.line,
                    valueColor: AlwaysStoppedAnimation<Color>(qColor.withValues(alpha: 0.7)),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(startStr, style: TextStyle(fontSize: 9, color: colors.inkMuted)),
                    Text(endStr,   style: TextStyle(fontSize: 9, color: colors.inkMuted)),
                  ],
                ),
              ],
            ),
          ),
          // ── Next yoga preview ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.line)),
            ),
            child: Row(
              children: [
                Text(
                  AppStrings.nextYogaLabel(language).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06 * 9,
                    color: colors.inkMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: nextQColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nextName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  AppStrings.nakshatraUntil(nextStart, language),
                  style: TextStyle(fontSize: 10, color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Karana list ───────────────────────────────────────────────────────────────

class _KaranaList extends StatelessWidget {
  final List<KaranaInfo> karanas;
  final Duration tz;
  final AppLanguage language;
  final GlobalKey currentKey;

  const _KaranaList({
    required this.karanas,
    required this.tz,
    required this.language,
    required this.currentKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final now = DateTime.now().toUtc();

    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < karanas.length; i++)
            _KaranaRow(
              karana: karanas[i],
              tz: tz,
              language: language,
              now: now,
              isLast: i == karanas.length - 1,
              currentKey: currentKey,
            ),
        ],
      ),
    );
  }
}

class _KaranaRow extends StatelessWidget {
  final KaranaInfo karana;
  final Duration tz;
  final AppLanguage language;
  final DateTime now;
  final bool isLast;
  final GlobalKey currentKey;

  const _KaranaRow({
    required this.karana,
    required this.tz,
    required this.language,
    required this.now,
    required this.isLast,
    required this.currentKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final isPast    = karana.end.isBefore(now);
    final isCurrent = !karana.start.isAfter(now) && now.isBefore(karana.end);
    final isInausp  = karana.type.isInauspicious;

    final dotColor  = karana.type.dotColor;
    final name      = AppStrings.karanaName(karana.type, language);
    final quality   = AppStrings.karanaQuality(karana.type, language);
    final startStr  = formatLocalTime(karana.start, tz);
    final endStr    = formatLocalTime(karana.end, tz);

    Color bgColor = Colors.transparent;
    if (isCurrent && isInausp) {
      bgColor = colors.muWarn.withValues(alpha: 0.07);
    } else if (isCurrent) {
      bgColor = colors.shukla.withValues(alpha: 0.06);
    }

    return Container(
      key: isCurrent ? currentKey : null,
      decoration: BoxDecoration(
        color: bgColor,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Opacity(
        opacity: isPast ? 0.38 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrent && isInausp
                            ? colors.muWarn
                            : isCurrent
                                ? colors.shukla
                                : colors.ink,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      _NowPill(isInausp: isInausp, colors: colors),
                    ],
                  ],
                ),
              ),
              Text(
                quality,
                style: TextStyle(fontSize: 9, color: colors.inkMuted),
                textAlign: TextAlign.right,
              ),
              const SizedBox(width: 10),
              Text(
                '$startStr – $endStr',
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent
                      ? (isInausp ? colors.muWarn : colors.shukla)
                      : colors.inkSoft,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Five Elements summary card ────────────────────────────────────────────────

class _FiveElementsCard extends StatelessWidget {
  final DayData dayData;
  final PanchaData pancha;
  final Duration tz;
  final AppLanguage language;
  final DateTime date;

  const _FiveElementsCard({
    required this.dayData,
    required this.pancha,
    required this.tz,
    required this.language,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final now = DateTime.now().toUtc();

    final currentKarana = pancha.karanas.firstWhere(
      (k) => !k.start.isAfter(now) && now.isBefore(k.end),
      orElse: () => pancha.karanas.last,
    );
    final yoga = pancha.currentYoga;
    final yogaColor = yoga.quality.color;

    final karanaIsInausp = currentKarana.type.isInauspicious;
    final karanaIsAusp = !currentKarana.type.isFixed && !karanaIsInausp;
    final karanaColor = currentKarana.type.dotColor;

    final tithiName = switch (language) {
      AppLanguage.hindiDevanagari => dayData.tithi.fullNameDeva,
      AppLanguage.tamil           => dayData.tithi.fullNameTamil,
      AppLanguage.bengali         => dayData.tithi.fullNameBengali,
      _ => dayData.tithi.fullNameEn,
    };

    final nakshatraName = switch (language) {
      AppLanguage.hindiDevanagari => dayData.nakshatra.nameDeva,
      AppLanguage.tamil           => dayData.nakshatra.nameTamil,
      AppLanguage.bengali         => dayData.nakshatra.nameBengali,
      _ => dayData.nakshatra.nameEn,
    };

    final yogaBg = yogaColor.withValues(alpha: 0.07);
    final karanaBg = karanaIsInausp
        ? colors.muWarn.withValues(alpha: 0.07)
        : karanaIsAusp
            ? const Color(0xFF2A8A5A).withValues(alpha: 0.07)
            : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _FiveRow(
            icon: '☼',
            label: AppStrings.varaLabel(language),
            name: AppStrings.weekdayTitle(date.weekday, language),
            sub: AppStrings.varaRulerSub(date.weekday, language),
            time: '—',
            colors: colors,
          ),
          _FiveRow(
            icon: '◐',
            label: AppStrings.tithiLabel(language),
            name: tithiName,
            time: formatLocalTime(dayData.tithi.end, tz),
            colors: colors,
          ),
          _FiveRow(
            icon: '✦',
            label: AppStrings.nakshatraLabel(language),
            name: nakshatraName,
            time: formatLocalTime(dayData.nakshatra.end, tz),
            colors: colors,
          ),
          _FiveRow(
            icon: '⊕',
            label: AppStrings.yogaLabel(language),
            name: AppStrings.yogaName(yoga.number, language),
            nameColor: yogaColor,
            iconColor: yogaColor,
            qualityDotColor: yogaColor,
            qualityText: AppStrings.yogaQualityLabel(yoga.quality, language),
            qualityTextColor: yogaColor,
            time: formatLocalTime(yoga.end, tz),
            timeColor: yoga.quality == YogaQuality.inauspicious ? yogaColor : null,
            timeBold: yoga.quality == YogaQuality.inauspicious,
            rowBackground: yogaBg,
            colors: colors,
          ),
          _FiveRow(
            icon: '◑',
            label: AppStrings.karanaLabel(language),
            name: AppStrings.karanaName(currentKarana.type, language),
            nameColor: (karanaIsInausp || karanaIsAusp) ? karanaColor : null,
            iconColor: (karanaIsInausp || karanaIsAusp) ? karanaColor : null,
            qualityDotColor: karanaColor,
            qualityText: karanaIsInausp
                ? AppStrings.avoidNewBeginnings(language)
                : AppStrings.karanaQuality(currentKarana.type, language),
            qualityTextColor: karanaColor,
            time: formatLocalTime(currentKarana.end, tz),
            timeColor: karanaIsInausp ? colors.muWarn : null,
            timeBold: karanaIsInausp,
            rowBackground: karanaBg,
            isLast: true,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _FiveRow extends StatelessWidget {
  final String icon;
  final String label;
  final String name;
  final String? sub;
  final Color? nameColor;
  final Color? iconColor;
  final Color? qualityDotColor;
  final String? qualityText;
  final Color? qualityTextColor;
  final String time;
  final Color? timeColor;
  final bool timeBold;
  final Color rowBackground;
  final bool isLast;
  final TithikaColors colors;

  const _FiveRow({
    required this.icon,
    required this.label,
    required this.name,
    this.sub,
    this.nameColor,
    this.iconColor,
    this.qualityDotColor,
    this.qualityText,
    this.qualityTextColor,
    required this.time,
    this.timeColor,
    this.timeBold = false,
    this.rowBackground = Colors.transparent,
    this.isLast = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: rowBackground,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(
              icon,
              style: TextStyle(fontSize: 12, color: iconColor ?? colors.inkMuted),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08 * 8,
                  color: colors.inkMuted,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: nameColor ?? colors.ink,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(fontSize: 9, color: colors.inkMuted),
                  ),
                if (qualityText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        if (qualityDotColor != null) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: qualityDotColor,
                            ),
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          qualityText!,
                          style: TextStyle(
                            fontSize: 9,
                            color: qualityTextColor ?? colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: timeColor ?? colors.inkSoft,
                fontWeight: timeBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── NOW pill ──────────────────────────────────────────────────────────────────

class _NowPill extends StatelessWidget {
  final bool isInausp;
  final TithikaColors colors;

  const _NowPill({required this.isInausp, required this.colors});

  @override
  Widget build(BuildContext context) {
    final bg = isInausp ? colors.muWarn : colors.shukla;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'NOW',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
