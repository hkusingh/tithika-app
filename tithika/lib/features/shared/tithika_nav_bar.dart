import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class TithikaNavBar extends StatelessWidget {
  final String? title;
  final Widget? centerOverride;

  const TithikaNavBar({super.key, this.title, this.centerOverride});

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
            // Center: title or override widget
            if (centerOverride != null)
              centerOverride!
            else if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                      fontSize: 14,
                    ),
              ),

            // Left: Tithika + home icon
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.go('/'),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tithika',
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.home_rounded, color: colors.inkSoft, size: 22),
                  ],
                ),
              ),
            ),

            // Right: nav icons
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.flare_rounded, color: colors.inkSoft, size: 22),
                    onPressed: () => context.go('/festivals'),
                    tooltip: 'Festivals',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_month_rounded, color: colors.inkSoft, size: 22),
                    onPressed: () => context.go('/month'),
                    tooltip: 'Month view',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: colors.inkSoft, size: 22),
                    onPressed: () => context.go('/settings'),
                    tooltip: 'Settings',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
