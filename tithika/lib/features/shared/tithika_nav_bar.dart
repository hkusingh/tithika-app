import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';

class TithikaNavBar extends StatefulWidget {
  /// Optional widget to render in the center slot instead of 'TITHIKA'.
  final Widget? centerOverride;

  const TithikaNavBar({super.key, this.centerOverride});

  @override
  State<TithikaNavBar> createState() => _TithikaNavBarState();
}

class _TithikaNavBarState extends State<TithikaNavBar> {
  OverlayEntry? _menuEntry;

  bool get _isOpen => _menuEntry != null;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _removeMenu() {
    _menuEntry?.remove();
    _menuEntry?.dispose();
    _menuEntry = null;
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final navOffset = renderBox.localToGlobal(Offset.zero);
    final navHeight = renderBox.size.height;

    _menuEntry = OverlayEntry(
      builder: (overlayCtx) {
        final colors = TithikaColors.of(overlayCtx);
        return Stack(
          children: [
            // Full-screen transparent barrier — tap to dismiss.
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Dropdown — full width, positioned just below the nav bar.
            Positioned(
              top: navOffset.dy + navHeight,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: _HamburgerMenu(
                  onSelect: _navigate,
                  colors: colors,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_menuEntry!);
    setState(() {});
  }

  void _closeMenu() {
    _removeMenu();
    if (mounted) setState(() {});
  }

  void _navigate(String route) {
    _closeMenu();
    context.go(route);
  }

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
            if (widget.centerOverride != null)
              widget.centerOverride!
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

            // Left: hamburger · home
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isOpen ? Icons.close_rounded : Icons.menu_rounded,
                      color: _isOpen ? colors.shukla : colors.ink,
                      size: 22,
                    ),
                    onPressed: _toggleMenu,
                    tooltip: 'More',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.home_rounded, color: colors.ink, size: 22),
                    onPressed: () {
                      _closeMenu();
                      context.go(Routes.dayView);
                    },
                    tooltip: 'Home',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
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
                    onPressed: () {
                      _closeMenu();
                      context.go(Routes.monthView);
                    },
                    tooltip: 'Month view',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune_rounded,
                        color: colors.inkSoft, size: 22),
                    onPressed: () {
                      _closeMenu();
                      context.go(Routes.settings);
                    },
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

// ── Hamburger dropdown ─────────────────────────────────────────────────────────

class _HamburgerMenu extends StatelessWidget {
  final void Function(String route) onSelect;
  final TithikaColors colors;

  const _HamburgerMenu({required this.onSelect, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(
          top:    BorderSide(color: colors.lineStrong),
          bottom: BorderSide(color: colors.lineStrong),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(
            icon: Icons.access_time_rounded,
            label: 'Hora',
            sub: 'Planetary hours',
            colors: colors,
            onTap: () => onSelect(Routes.hora),
          ),
          _ItemDivider(colors: colors),
          _MenuItem(
            icon: Icons.brightness_high_rounded,
            label: 'Muhurta',
            sub: 'Rahu Kaal · Choghadiya',
            colors: colors,
            onTap: () => onSelect(Routes.muhurta),
          ),
          _ItemDivider(colors: colors),
          _MenuItem(
            icon: Icons.auto_stories_rounded,
            label: 'Panchanga',
            sub: 'Yoga · Karana · five elements',
            colors: colors,
            onTap: () => onSelect(Routes.panchanga),
          ),
          Container(
            height: 1,
            color: colors.lineStrong,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          _MenuItem(
            icon: Icons.celebration_rounded,
            label: 'Festivals',
            sub: 'Hindu festivals',
            colors: colors,
            onTap: () => onSelect(Routes.festivals),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final TithikaColors colors;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.inkSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(color: colors.inkMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _ItemDivider extends StatelessWidget {
  final TithikaColors colors;
  const _ItemDivider({required this.colors});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: colors.line);
}
