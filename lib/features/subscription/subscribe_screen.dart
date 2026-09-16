import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/subscribe_controller.dart';
import '../../core/models/subscription.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';

/// The paywall. Two plan cards, one Cobalt CTA, no countdowns or badges.
/// Calm by default: the case for Pro is the numbers, not the colour.
class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({super.key});

  Future<void> _confirm(BuildContext context) async {
    final ctrl = context.read<SubscribeController>();
    final wantsPro = ctrl.selected == Plan.pro;
    final ok = await ctrl.confirm();
    if (!ok || !context.mounted) return;
    showJmToast(
      context,
      title: wantsPro ? "You're on Pro" : "You're on Free",
      body: wantsPro
          ? '5 searches an hour across all ten sites, plus Save to Sheets.'
          : 'One search a day across three sites.',
      tone: ToastTone.success,
    );
    context.canPop() ? context.pop() : context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SubscribeController>();
    final c = context.jm;
    final pro = ctrl.selected == Plan.pro;

    return JmPage(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ctrl.error != null) ...[ErrorLine(ctrl.error!), const SizedBox(height: JmSpace.x3)],
          PrimaryButton(
            label: ctrl.alreadyPro
                ? (pro ? "You're on Pro" : 'Switch to Free')
                : (pro ? 'Start Pro · $proPriceLabel / $proPricePeriod' : 'Stay on Free'),
            busyLabel: 'One moment…',
            busy: ctrl.busy,
            large: true,
            onPressed: ctrl.canConfirm ? () => _confirm(context) : null,
          ),
          const SizedBox(height: JmSpace.x2),
          Text(
            'Billed through the App Store or Google Play. Cancel any time; Pro stays on until the period ends.',
            style: context.type.meta.copyWith(color: c.faint, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JmLabel('Plans', color: c.oceanDeep),
          const SizedBox(height: JmSpace.x2),
          Text('Search more, sooner', style: context.type.display.copyWith(fontSize: 28)),
          const SizedBox(height: JmSpace.x2),
          Text(
            'Free covers a careful search a day. Pro is for the weeks you are actually applying.',
            style: context.type.body.copyWith(color: c.muted),
          ),
          const SizedBox(height: JmSpace.x6),
          _PlanCard(
            plan: Plan.pro,
            price: '$proPriceLabel / $proPricePeriod',
            selected: pro,
            current: ctrl.alreadyPro,
            onTap: () => ctrl.select(Plan.pro),
            features: const [
              '5 searches an hour',
              'All ten job sites',
              'Save every run to Google Sheets',
              'Up to 50 jobs per site',
            ],
          ),
          const SizedBox(height: JmSpace.x3),
          _PlanCard(
            plan: Plan.free,
            price: '₱0',
            selected: !pro,
            current: !ctrl.alreadyPro,
            onTap: () => ctrl.select(Plan.free),
            features: const [
              '1 search a day',
              'LinkedIn, JobStreet and Kalibrr',
              'Ranked results with reasons and red flags',
            ],
          ),
          const SizedBox(height: JmSpace.x6),
          Text(
            'Either way, every match shows why it fits. Pro just lets you run more of them.',
            style: context.type.meta,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.price,
    required this.selected,
    required this.current,
    required this.onTap,
    required this.features,
  });

  final Plan plan;
  final String price;
  final bool selected, current;
  final VoidCallback onTap;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.label} plan, $price${current ? ', your current plan' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: JmRadius.lgR,
          child: AnimatedContainer(
            duration: JmMotion.state,
            curve: JmMotion.ease,
            padding: const EdgeInsets.all(JmSpace.x4),
            decoration: BoxDecoration(
              color: selected ? c.oceanTint : c.card,
              borderRadius: JmRadius.lgR,
              border: Border.all(color: selected ? c.ocean : c.line, width: selected ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Radio(selected: selected),
                    const SizedBox(width: 10),
                    Text(plan.label, style: context.type.heading),
                    if (current) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: c.surface2, borderRadius: JmRadius.pillR),
                        child: Text(
                          'Current',
                          style: context.type.meta.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(price, style: context.type.stat.copyWith(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: JmSpace.x3),
                for (final f in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(Icons.check_rounded, size: 16, color: selected ? c.oceanDeep : c.muted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: context.type.ui.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: c.text),
                          ),
                        ),
                      ],
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

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return AnimatedContainer(
      duration: JmMotion.state,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.ocean : Colors.transparent,
        border: Border.all(color: selected ? c.ocean : c.lineStrong, width: 1.5),
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
    );
  }
}
