import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Which brand tint the art area uses. Text on it is always the deep
/// variant, so every tile passes contrast in both themes.
enum ArtHue { ocean, sky, match, volt }

/// Grid tile with an illustrated header: a soft tinted field with a big
/// icon and two decorative circles, then a title and one line of copy.
/// Used by the AI suggestions and the Tools grid so they read as one family.
class ArtTile extends StatelessWidget {
  const ArtTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.hue = ArtHue.ocean,
    this.badge,
    this.badgeMuted = false,
    this.height = 194,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final ArtHue hue;
  final String? badge;
  final bool badgeMuted;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final (tint, deep, accent) = switch (hue) {
      ArtHue.ocean => (c.oceanTint, c.oceanDeep, c.ocean),
      ArtHue.sky => (c.skyTint, c.skyDeep, c.sky),
      ArtHue.match => (c.matchTint, c.matchDeep, c.match),
      ArtHue.volt => (c.voltTint, c.voltDeep, c.volt),
    };
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: JmRadius.lgR,
          child: Container(
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: JmRadius.lgR,
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Art
                SizedBox(
                  height: 84,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: tint)),
                      Positioned(right: -18, top: -22, child: _Blob(size: 84, color: accent.withValues(alpha: .18))),
                      Positioned(left: -10, bottom: -28, child: _Blob(size: 64, color: accent.withValues(alpha: .12))),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: JmColors.navy.withValues(alpha: .08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 24, color: deep),
                        ),
                      ),
                      if (badge != null)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeMuted ? c.surface2 : c.card,
                              borderRadius: JmRadius.pillR,
                            ),
                            child: Text(
                              badge!,
                              style: context.type.meta.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeMuted ? c.muted : deep,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Copy
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.type.uiStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Expanded(
                            child: Text(
                              subtitle!,
                              style: context.type.meta.copyWith(fontSize: 12.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Two columns on phones, three from 720. Children get equal width.
class ArtGrid extends StatelessWidget {
  const ArtGrid({super.key, required this.children, this.gap = JmSpace.x3});
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth >= 720 ? 3 : 2;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}
