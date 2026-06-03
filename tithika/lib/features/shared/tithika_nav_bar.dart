import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';

class TithikaNavBar extends StatelessWidget {
  /// Optional widget to render in the center slot instead of 'TITHIKA'.
  final Widget? centerOverride;

  const TithikaNavBar({super.key, this.centerOverride});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center: TITHIKA label or override
            if (centerOverride != null)
              centerOverride!
            else
              Text(
                'TITHIKA',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      fontSize: 14,
                      letterSpacing: 0.06,
                    ),
              ),

            // Left: home
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.home_rounded, color: colors.ink, size: 22),
                onPressed: () => context.go(Routes.dayView),
                tooltip: 'Home',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),

            // Right: month · settings
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.calendar_month_rounded,
                        color: colors.inkSoft, size: 22),
                    onPressed: () => context.go(Routes.monthView),
                    tooltip: 'Month view',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune_rounded,
                        color: colors.inkSoft, size: 22),
                    onPressed: () => context.go(Routes.settings),
                    tooltip: 'Settings',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
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
