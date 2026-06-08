import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';

class TithikaTabBar extends ConsumerWidget {
  const TithikaTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = TithikaColors.of(context);
    final language = ref.watch(appSettingsProvider).language;
    final location = GoRouterState.of(context).matchedLocation;

    final isFestivals = location.startsWith('/festivals');
    final isMuhurta   = location.startsWith('/muhurta');
    final isHora      = location.startsWith('/hora');
    final isPanchanga = location.startsWith('/panchanga');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? colors.krishna.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.75),
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: colors.krishna.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _TabItem(
              icon: Icons.auto_awesome,
              label: AppStrings.festivals(language),
              active: isFestivals,
              onTap: () => context.go(Routes.festivals),
              colors: colors,
            ),
            _TabItem(
              icon: Icons.brightness_high_rounded,
              label: AppStrings.muhurta(language),
              active: isMuhurta,
              onTap: () => context.go(Routes.muhurta),
              colors: colors,
            ),
            _TabItem(
              icon: Icons.access_time_rounded,
              label: AppStrings.hora(language),
              active: isHora,
              onTap: () => context.go(Routes.hora),
              colors: colors,
            ),
            _TabItem(
              icon: Icons.auto_stories_rounded,
              label: AppStrings.panchaTitle(language),
              active: isPanchanga,
              onTap: () => context.go(Routes.panchanga),
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final TithikaColors colors;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: active
              ? BoxDecoration(
                  color: colors.shukla.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: active ? colors.shukla : colors.ink),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? colors.shukla : colors.ink,
                  letterSpacing: 0.02,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
