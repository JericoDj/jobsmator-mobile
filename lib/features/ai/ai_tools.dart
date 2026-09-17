import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../shared/widgets/art_tile.dart';

/// The six things the assistant can hand off to. Shared by the fan of
/// tiles in the hero and the side sheet.
typedef AiTool = ({
  IconData icon,
  String title,
  String short,
  String blurb,
  ArtHue hue,
  String? route,
  bool upload,
});

const aiTools = <AiTool>[
  (
    icon: Icons.search_rounded,
    title: 'Find matching jobs',
    short: 'Find jobs',
    blurb: 'Ten sites, ranked with reasons.',
    hue: ArtHue.ocean,
    route: null,
    upload: true,
  ),
  (
    icon: Icons.description_outlined,
    title: 'Analyze my resume',
    short: 'Resume',
    blurb: 'What recruiters see first.',
    hue: ArtHue.sky,
    route: 'resume-analyzer',
    upload: false,
  ),
  (
    icon: Icons.track_changes_rounded,
    title: 'Analyze this job',
    short: 'Job match',
    blurb: 'Score one listing against you.',
    hue: ArtHue.match,
    route: 'job-match',
    upload: false,
  ),
  (
    icon: Icons.mail_outline_rounded,
    title: 'Write an application',
    short: 'Apply',
    blurb: 'Short, specific, in your voice.',
    hue: ArtHue.volt,
    route: 'application-email',
    upload: false,
  ),
  (
    icon: Icons.record_voice_over_outlined,
    title: 'Prepare me for interview',
    short: 'Interview',
    blurb: 'Likely questions, strong answers.',
    hue: ArtHue.ocean,
    route: 'interview-prep',
    upload: false,
  ),
  (
    icon: Icons.payments_outlined,
    title: 'What should I earn?',
    short: 'Salary',
    blurb: 'A realistic range for your level.',
    hue: ArtHue.sky,
    route: 'salary',
    upload: false,
  ),
];

void openAiTool(BuildContext context, AiTool t) {
  if (t.upload) {
    context.go(AppRoutes.upload);
  } else {
    context.push(AppRoutes.tool(t.route!));
  }
}

(Color tint, Color deep) aiHueColors(JmColors c, ArtHue hue) => switch (hue) {
  ArtHue.ocean => (c.oceanTint, c.oceanDeep),
  ArtHue.sky => (c.skyTint, c.skyDeep),
  ArtHue.match => (c.matchTint, c.matchDeep),
  ArtHue.volt => (c.voltTint, c.voltDeep),
};
