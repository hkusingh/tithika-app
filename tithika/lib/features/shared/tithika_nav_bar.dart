import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class TithikaNavBar extends StatelessWidget {
  final String? title;
  final Widget? centerOverride;

  const TithikaNavBar({super.key, this.title, this.centerOverride});

  @override
  Widget build(BuildContext context) {
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
                      color: TithikaColors.ink,
                      fontSize: 14,
                    ),
              ),

            // Left: Tithika + home icon
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.go('/'),
                behavior: HitTestBehavior.opaque,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tithika',
                      style: TextStyle(
                        color: TithikaColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.home_rounded,
                      color: TithikaColors.inkSoft,
                      size: 22,
                    ),
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
                    icon: const Icon(Icons.flare_rounded,
                        color: TithikaColors.inkSoft, size: 22),
                    onPressed: () => context.go('/festivals'),
                    tooltip: 'Festivals',
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_rounded,
                        color: TithikaColors.inkSoft, size: 22),
                    onPressed: () => context.go('/month'),
                    tooltip: 'Month view',
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded,
                        color: TithikaColors.inkSoft, size: 22),
                    onPressed: () => context.go('/settings'),
                    tooltip: 'Settings',
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
