import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/models/tool.dart';
import '../../providers/subscription_provider.dart';
import '../shared/widgets/art_tile.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/tab_header.dart';

/// Utilities the user runs one at a time. Premium ones carry a small mark;
/// the paywall explains on tap, the grid never nags.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pro = context.watch<SubscriptionProvider>().isPro;
    return JmPage(
      maxWidth: JmLayout.results,
      padding: JmPage.tabPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabHeader(title: 'Tools', subtitle: 'Built on your resume and preferences, not a template.'),
          const SizedBox(height: JmSpace.x6),
          ArtGrid(
            children: [
              for (final (i, t) in tools.indexed)
                ArtTile(
                  icon: t.icon,
                  title: t.title,
                  subtitle: t.blurb,
                  hue: ArtHue.values[i % ArtHue.values.length],
                  badge: t.premium ? 'Pro' : null,
                  badgeMuted: t.premium && !pro,
                  onTap: () => context.push(AppRoutes.tool(t.id)),
                ),
            ],
          ),
          if (!pro) ...[
            const SizedBox(height: JmSpace.x6),
            Text('Tools marked Pro are part of the Pro plan.', style: context.type.meta),
          ],
        ],
      ),
    );
  }
}
