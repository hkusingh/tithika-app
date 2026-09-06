import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/festival_names.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../models/festival_content.dart';
import '../../models/lunar_month.dart';
import '../../services/festival_content_service.dart';
import '../../state/providers.dart';
import 'festival_bell.dart';

const _kHeaderHeight = 240.0;

/// Header controls sit on arbitrary festival photography — some of it bright,
/// pale or busy — so they carry their own scrim and rim rather than relying on
/// the image behind them for contrast.
final _headerButtonDecoration = BoxDecoration(
  color: Colors.black.withValues(alpha: 0.6),
  shape: BoxShape.circle,
  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.5),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ],
);

const _headerIconShadows = [Shadow(blurRadius: 4, color: Colors.black87)];

// Canonical festival keys that have a bundled image asset.
// Value = base filename without extension. The loader tries .png then .jpg.
const _festivalImages = <String, String>{
  'Maha Shivaratri':                        'maha_shivaratri',
  'Vasant Panchami':                        'vasant_panchami',
  'Makar Sankranti / Pongal':              'makar_sankranti',
  'Holika Dahan':                           'holika_dahan',
  'Holi':                                   'holi',
  'Gudi Padwa / Ugadi / Chaitra Navratri': 'gudi_padwa',
  'Hanuman Jayanti':                        'hanuman_jayanti',
  'Ram Navami':                             'ram_navami',
  'Baisakhi / Vishu':                       'baisakhi',
  'Akshaya Tritiya':                        'akshaya_tritiya',
  'Buddha Purnima':                         'buddha_purnima',
  'Vat Savitri':                            'vat_savitri',
  'Ganga Dussehra':                         'ganga_dussehra',
  'Nirjala Ekadashi':                       'nirjala_ekadashi',
  'Rath Yatra':                             'rath_yatra',
  'Devshayani Ekadashi':                    'devshayani_ekadashi',
  'Guru Purnima':                           'guru_purnima',
  'Hariyali Teej':                          'hariyali_teej',
  'Nag Panchami':                           'nag_panchami',
  'Raksha Bandhan':                         'raksha_bandhan',
  'Hartalika Teej':                         'hartalika_teej',
  'Ganesh Chaturthi':                       'ganesh_chaturthi',
  'Krishna Janmashtami':                    'krishna_janmashtami',
  'Anant Chaturdashi':                      'anant_chaturdashi',
  'Jivitputrika Vrat (Jitiya)':             'jivitputrika',
  'Mahalaya Amavasya':                      'mahalaya_amavasya',
  'Sharad Navratri':                        'sharad_navratri',
  'Golu':                                   'golu',
  'Maha Ashtami':                           'maha_ashtami',
  'Maha Navami':                            'maha_navami',
  'Vijayadashami':                          'vijayadashami',
  'Sharad Purnima':                         'sharad_purnima',
  'Karva Chauth':                           'karva_chauth',
  'Ahoi Ashtami':                           'ahoi_ashtami',
  'Dhanteras':                              'dhanteras',
  'Naraka Chaturdashi':                     'naraka_chaturdashi',
  'Diwali':                                 'diwali',
  'Govardhan Puja':                         'govardhan_puja',
  'Bhai Dooj':                              'bhai_dooj',
  'Chhath — Nahay Khay':                    'chhath_nahay_khay',
  'Chhath — Kharna':                        'chhath_kharna',
  'Chhath — Sandhya Arghya':               'chhath_sandhya',
  'Chhath — Usha Arghya':                  'chhath_usha',
  'Devutthana Ekadashi':                    'devutthana_ekadashi',
  'Tulsi Vivah':                            'tulsi_vivah',
  'Kartik Purnima':                         'kartik_purnima',
  'Gita Jayanti':                           'gita_jayanti',
};

void showFestivalDetail(BuildContext context, FestivalEntry entry) {
  final key = entry.data.festivalName;
  if (key == null) return;
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black54,
      pageBuilder: (ctx, _, __) =>
          _FestivalDetailPage(entry: entry, canonicalKey: key),
      transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

// ── Detail page ───────────────────────────────────────────────────────────────

class _FestivalDetailPage extends ConsumerStatefulWidget {
  final FestivalEntry entry;
  final String canonicalKey;

  const _FestivalDetailPage(
      {required this.entry, required this.canonicalKey});

  @override
  ConsumerState<_FestivalDetailPage> createState() =>
      _FestivalDetailPageState();
}

class _FestivalDetailPageState extends ConsumerState<_FestivalDetailPage> {
  FestivalContent? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final lang = ref.read(appSettingsProvider).language;
    final content =
        await FestivalContentService.load(widget.canonicalKey, lang);
    if (mounted) {
      setState(() {
        _content = content;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final lang = ref.watch(appSettingsProvider.select((s) => s.language));
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final data = widget.entry.data;
    final monthName = switch (lang) {
      AppLanguage.hindiDevanagari => data.lunarMonth.nameDeva,
      AppLanguage.tamil           => data.lunarMonth.nameTamil,
      AppLanguage.bengali         => data.lunarMonth.nameBengali,
      _                           => data.lunarMonth.nameEn,
    };
    final pakshaLabel = AppStrings.paksha(data.tithi.paksha, lang);
    final hinduDate = '$monthName · $pakshaLabel ${data.tithi.pakshaNumber}';

    final d = widget.entry.date;
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final gregDate = '${wd[d.weekday - 1]}, ${mo[d.month - 1]} ${d.day}';

    final imageBase = _festivalImages[widget.canonicalKey];

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          SizedBox(
            height: _kHeaderHeight + topPad,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image or gradient background — tries .png then .jpg
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(0)),
                  child: imageBase != null
                      ? Image.asset(
                          'assets/festival_images/$imageBase.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/festival_images/$imageBase.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _GradientBg(festivalKey: widget.canonicalKey),
                          ),
                        )
                      : _GradientBg(festivalKey: widget.canonicalKey),
                ),

                // Bottom gradient overlay for text readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),

                // Close button
                Positioned(
                  top: topPad + 10,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: _headerButtonDecoration,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                        shadows: _headerIconShadows,
                      ),
                    ),
                  ),
                ),

                // Reminder bell, in the header so it appears no matter which
                // surface opened this page (festivals list, day view badge,
                // month view list). Sits left of the close button; the title
                // block below is already inset right: 56, so this is clear.
                Positioned(
                  top: topPad + 10,
                  right: 52,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: _headerButtonDecoration,
                    child: Center(
                      child: FestivalBell(
                        canonicalKey: widget.canonicalKey,
                        size: 17,
                        onDarkOverlay: true,
                      ),
                    ),
                  ),
                ),

                // Festival title + subtitle at bottom of header
                Positioned(
                  left: 20,
                  right: 56,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        FestivalNames.localize(widget.canonicalKey, lang) ??
                            widget.canonicalKey,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black54)
                          ],
                        ),
                      ),
                      if (_content?.subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          _content!.subtitle!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black45)
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: colors.shukla, strokeWidth: 1.5),
                  )
                : _content == null
                    ? Center(
                        child: Text(
                          'No details available yet.',
                          style: TextStyle(
                              color: colors.inkMuted, fontSize: 13),
                        ),
                      )
                    : _Body(
                        content: _content!,
                        hinduDate: hinduDate,
                        gregDate: gregDate,
                        colors: colors,
                        language: lang,
                        bottomPad: bottomPad,
                        onGoToDate: () {
                          Navigator.of(context).pop();
                          ref.read(selectedDateProvider.notifier).state =
                              widget.entry.date;
                          context.go(Routes.dayView);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Body content ──────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final FestivalContent content;
  final String hinduDate;
  final String gregDate;
  final TithikaColors colors;
  final AppLanguage language;
  final double bottomPad;
  final VoidCallback onGoToDate;

  const _Body({
    required this.content,
    required this.hinduDate,
    required this.gregDate,
    required this.colors,
    required this.language,
    required this.bottomPad,
    required this.onGoToDate,
  });

  @override
  Widget build(BuildContext context) {
    final chips = Row(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _DateChip(
                label: hinduDate,
                bg: colors.shukla.withValues(alpha: 0.15),
                fg: colors.shukla),
            _DateChip(
                label: gregDate,
                bg: colors.ink.withValues(alpha: 0.07),
                fg: colors.inkSoft),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onGoToDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.krishna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.krishna.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 11, color: colors.krishna),
                const SizedBox(width: 4),
                Text(
                  'Go to date',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.krishna,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (content.isCombined) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chips,
            if (content.intro != null) ...[
              const SizedBox(height: 14),
              Text(
                content.intro!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                      fontSize: 13,
                      height: 1.6,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            for (final section in content.sections)
              _CombinedSectionCard(
                section: section,
                colors: colors,
                language: language,
              ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chips,
          const SizedBox(height: 18),

          // About box
          _SectionBox(
            label: AppStrings.about(language),
            colors: colors,
            child: Text(
              content.description,
              style: scriptStyle(
                language,
                Theme.of(context).textTheme.bodyMedium,
                color: colors.inkSoft,
                fontSize: 14,
              ).copyWith(height: 1.65),
            ),
          ),

          // Observances box
          if (content.observances.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionBox(
              label: AppStrings.howToObserve(language),
              colors: colors,
              child: Column(
                children: [
                  for (int i = 0; i < content.observances.length; i++)
                    _ObservanceRow(
                      text: content.observances[i],
                      isLast: i == content.observances.length - 1,
                      colors: colors,
                      language: language,
                      context: context,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Combined festival section card ───────────────────────────────────────────

class _CombinedSectionCard extends StatelessWidget {
  final FestivalSection section;
  final TithikaColors colors;
  final AppLanguage language;

  const _CombinedSectionCard({
    required this.section,
    required this.colors,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.region != null) ...[
                  Text(
                    section.region!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: colors.inkMuted,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  section.description,
                  style: scriptStyle(
                    language,
                    Theme.of(context).textTheme.bodySmall,
                    color: colors.inkSoft,
                    fontSize: 13,
                  ).copyWith(height: 1.6),
                ),
              ],
            ),
          ),
          if (section.observances.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Text(
                AppStrings.howToObserve(language),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: colors.shukla,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Divider(height: 1, color: colors.ink.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                children: [
                  for (int i = 0; i < section.observances.length; i++)
                    _ObservanceRow(
                      text: section.observances[i],
                      isLast: i == section.observances.length - 1,
                      colors: colors,
                      language: language,
                      context: context,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Gradient background ───────────────────────────────────────────────────────

class _GradientBg extends StatelessWidget {
  final String festivalKey;
  const _GradientBg({required this.festivalKey});

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors(festivalKey);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

List<Color> _gradientColors(String key) {
  final k = key.toLowerCase();
  if (k.contains('holika') || k.contains('shivaratri')) {
    return const [Color(0xFF3D1A0A), Color(0xFF7A2E10), Color(0xFFC04A18)];
  }
  if (k.contains('diwali') || k.contains('dhanteras') ||
      k.contains('naraka') || k.contains('mahalaya') ||
      k.contains('karva')) {
    return const [Color(0xFF060A18), Color(0xFF101830), Color(0xFF1A2848)];
  }
  if (k.contains('ram') || k.contains('hanuman') ||
      k.contains('guru') || k.contains('akshaya') || k.contains('gita')) {
    return const [Color(0xFF2A1800), Color(0xFF7A4A00), Color(0xFFC07800)];
  }
  if (k.contains('navratri') || k.contains('gudi') ||
      k.contains('ugadi') || k.contains('vasant') || k.contains('teej')) {
    return const [Color(0xFF1A0A2A), Color(0xFF5A1A6A), Color(0xFF9040A0)];
  }
  if (k.contains('ganga') || k.contains('chhath') || k.contains('rath')) {
    return const [Color(0xFF0A1A3A), Color(0xFF1A3A7A), Color(0xFF2060C0)];
  }
  if (k.contains('baisakhi') || k.contains('pongal') ||
      k.contains('sankranti') || k.contains('govardhan')) {
    return const [Color(0xFF1A1A0A), Color(0xFF4A4A0A), Color(0xFF808018)];
  }
  if (k.contains('janmashtami') || k.contains('krishna') ||
      k.contains('holi')) {
    return const [Color(0xFF0A0A2A), Color(0xFF1A1A5A), Color(0xFF283878)];
  }
  if (k.contains('hariyali') || k.contains('hartalika') ||
      k.contains('tulsi') || k.contains('nag')) {
    return const [Color(0xFF0A1A0A), Color(0xFF1A4A1A), Color(0xFF2A8A2A)];
  }
  if (k.contains('purnima') || k.contains('raksha') ||
      k.contains('ekadashi') || k.contains('sharad')) {
    return const [Color(0xFF0A0A2A), Color(0xFF1A1A4A), Color(0xFF2A2A7A)];
  }
  return const [Color(0xFF2A0A00), Color(0xFF6A2A00), Color(0xFFA04000)];
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _SectionBox extends StatelessWidget {
  final String label;
  final TithikaColors colors;
  final Widget child;
  const _SectionBox(
      {required this.label, required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.shukla,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Divider(height: 1, color: colors.ink.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _DateChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

class _ObservanceRow extends StatelessWidget {
  final String text;
  final bool isLast;
  final TithikaColors colors;
  final AppLanguage language;
  final BuildContext context;

  const _ObservanceRow({
    required this.text,
    required this.isLast,
    required this.colors,
    required this.language,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.ink.withValues(alpha: 0.07))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: colors.festival),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: scriptStyle(
                language,
                Theme.of(context).textTheme.bodySmall,
                color: colors.inkSoft,
                fontSize: 13.5,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

