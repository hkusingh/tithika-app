import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Sub-header that sits directly below [TithikaNavBar] on secondary screens.
/// Shows a large page title left-aligned and optional metadata right-aligned.
class PageTitleBar extends StatelessWidget {
  final String title;
  final String? meta;

  const PageTitleBar({super.key, required this.title, this.meta});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: colors.ink,
              letterSpacing: -0.01 * 19,
            ),
          ),
          if (meta != null) ...[
            const Spacer(),
            Text(
              meta!,
              style: TextStyle(fontSize: 10, color: colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
