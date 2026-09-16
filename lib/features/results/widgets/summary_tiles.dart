import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/models/job.dart';

/// Strong · Good · Weaker · Sites. Tapping a tier tile filters the list.
class SummaryTiles extends StatelessWidget {
  const SummaryTiles({
    super.key,
    required this.strong,
    required this.good,
    required this.weaker,
    required this.sites,
    required this.active,
    required this.onTier,
  });

  final int strong, good, weaker, sites;
  final Tier? active;
  final ValueChanged<Tier?> onTier;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final total = (strong + good + weaker).clamp(1, 1 << 30);
    final tiles = [
      _Tile(label: 'Strong', value: strong, fill: strong / total, color: c.match, tier: Tier.strong),
      _Tile(label: 'Good', value: good, fill: good / total, color: c.volt, tier: Tier.good),
      _Tile(label: 'Weaker', value: weaker, fill: weaker / total, color: c.faint, tier: Tier.skip),
      _Tile(label: 'Sites', value: sites, fill: 1, color: c.sky, tier: null),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 560 ? 4 : 2;
        final gap = JmSpace.x3;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              SizedBox(
                width: w,
                child: _StatTile(
                  tile: t,
                  selected: t.tier != null && active == t.tier,
                  dimmed: active != null && t.tier != null && active != t.tier,
                  onTap: t.tier == null ? null : () => onTier(t.tier),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile {
  const _Tile({required this.label, required this.value, required this.fill, required this.color, required this.tier});
  final String label;
  final int value;
  final double fill;
  final Color color;
  final Tier? tier;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.tile, required this.selected, required this.dimmed, this.onTap});
  final _Tile tile;
  final bool selected, dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${tile.value} ${tile.label}${onTap == null ? '' : ', filter'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: JmRadius.mdR,
          child: AnimatedContainer(
            duration: JmMotion.state,
            curve: JmMotion.ease,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: selected ? c.oceanTint : c.card,
              borderRadius: JmRadius.mdR,
              border: Border.all(color: selected ? c.ocean : c.line, width: selected ? 1.5 : 1),
            ),
            child: AnimatedOpacity(
              duration: JmMotion.state,
              opacity: dimmed ? .55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JmLabel(tile.label, color: selected ? c.oceanDeep : c.muted),
                  const SizedBox(height: 2),
                  Text('${tile.value}', style: context.type.stat),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Positioned.fill(child: ColoredBox(color: c.surface2)),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: tile.fill.clamp(0, 1),
                            heightFactor: 1,
                            child: ColoredBox(color: tile.color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
