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

/// The paywall. A Pro card with a monthly/yearly switch, a Free card, one
/// Cobalt CTA. Calm by default: the case for Pro is the numbers, not the
/// colour — the only badge is the yearly saving, because that is a number.
class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  final _voucherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fallback prices paint immediately; the store's localised ones replace them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SubscribeController>().loadOffers();
    });
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _confirm(BuildContext context) async {
    final ctrl = context.read<SubscribeController>();
    final wantsPro = ctrl.selected == Plan.pro;
    final ok = await ctrl.confirm();
    if (!ok || !context.mounted) return;
    showJmToast(
      context,
      title: wantsPro ? "You're on Pro" : "You're on Free",
      body: wantsPro
          ? 'Renews ${ctrl.term == ProTerm.yearly ? 'yearly' : 'monthly'}. All ten job sites, five searches a day, AI tools and Sheets export.'
          : 'One search a day across three sites.',
      tone: ToastTone.success,
    );
    context.canPop() ? context.pop() : context.go(AppRoutes.profile);
  }

  Future<void> _restore(BuildContext context) async {
    final ctrl = context.read<SubscribeController>();
    final active = await ctrl.restore();
    if (!context.mounted) return;
    if (ctrl.error != null) return; // ErrorLine already shows it
    showJmToast(
      context,
      title: active ? 'Pro restored' : 'Nothing to restore',
      body: active
          ? 'Your Pro purchase is back on this account.'
          : "We didn't find an active purchase for this account.",
      tone: active ? ToastTone.success : ToastTone.info,
    );
  }

  Future<void> _redeemVoucher(BuildContext context) async {
    final ctrl = context.read<SubscribeController>();
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    final ok = await ctrl.redeemVoucher(code);
    if (!ok || !context.mounted) return;

    _voucherController.clear();
    showJmToast(
      context,
      title: "Voucher Applied!",
      body: "You now have Pro access.",
      tone: ToastTone.success,
    );
    context.canPop() ? context.pop() : context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SubscribeController>();
    final c = context.jm;
    final pro = ctrl.selected == Plan.pro;
    final offer = ctrl.offer;

    return JmPage(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ctrl.error != null) ...[
            ErrorLine(ctrl.error!),
            const SizedBox(height: JmSpace.x3),
          ],
          PrimaryButton(
            label: ctrl.alreadyPro
                ? (pro ? "You're on Pro" : 'Switch to Free')
                : (pro
                      ? 'Start Pro · ${offer.price} / ${offer.term.unit}'
                      : 'Stay on Free'),
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
          Text(
            'Search more, sooner',
            style: context.type.display.copyWith(fontSize: 28),
          ),
          const SizedBox(height: JmSpace.x2),
          Text(
            'Free covers a careful search a day. Pro is for the weeks you are actually applying.',
            style: context.type.body.copyWith(color: c.muted),
          ),
          const SizedBox(height: JmSpace.x6),
          _PlanCard(
            plan: Plan.pro,
            price: '${offer.price} / ${offer.term.unit}',
            selected: pro,
            current: ctrl.alreadyPro,
            onTap: () => ctrl.select(Plan.pro),
            features: const [
              'All ten job sites, not three',
              'Five searches a day',
              'Cover letters, salary check and interview prep',
              'Every run saved to Google Sheets',
            ],
            extra: _TermPicker(
              offers: ctrl.offers,
              selected: ctrl.term,
              enabled: !ctrl.alreadyPro,
              onChanged: ctrl.selectTerm,
            ),
          ),
          const SizedBox(height: JmSpace.x3),
          _PlanCard(
            plan: Plan.free,
            price: '₱0',
            selected: !pro,
            current: !ctrl.alreadyPro,
            onTap: () => ctrl.select(Plan.free),
            features: const [
              'One search a day',
              'LinkedIn, JobStreet and Kalibrr',
              'Ranked results with reasons and red flags',
            ],
          ),
          const SizedBox(height: JmSpace.x6),
          Text(
            'Either way, every match shows why it fits. Pro just lets you run more of them.',
            style: context.type.meta,
          ),
          if (ctrl.usesStoreBilling) ...[
            const SizedBox(height: JmSpace.x4),
            Center(
              child: TextButton(
                onPressed: ctrl.busy ? null : () => _restore(context),
                child: const Text('Restore purchases'),
              ),
            ),
          ],
          const SizedBox(height: JmSpace.x6),
          // Voucher Section
          JmLabel('Have a promo code?', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    hintText: 'Enter voucher code',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: JmRadius.mdR,
                      borderSide: BorderSide(color: c.line),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: JmSpace.x2),
              SecondaryButton(
                label: 'Apply',
                onPressed: ctrl.busy ? null : () => _redeemVoucher(context),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),
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
    this.extra,
  });

  final Plan plan;
  final String price;
  final bool selected, current;
  final VoidCallback onTap;
  final List<String> features;

  /// Sits between the header and the feature list (the Pro term picker).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${plan.label} plan, $price${current ? ', your current plan' : ''}',
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
              border: Border.all(
                color: selected ? c.ocean : c.line,
                width: selected ? 1.5 : 1,
              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: JmRadius.pillR,
                        ),
                        child: Text(
                          'Current',
                          style: context.type.meta.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      price,
                      style: context.type.stat.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                if (extra != null) ...[
                  const SizedBox(height: JmSpace.x3),
                  extra!,
                ],
                const SizedBox(height: JmSpace.x3),
                for (final f in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: selected ? c.oceanDeep : c.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: context.type.ui.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: c.text,
                            ),
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

/// Monthly | Yearly, side by side. Each cell shows the price and, for
/// yearly, what it works out to per month plus the saving. Tapping a cell
/// selects Pro with that term.
class _TermPicker extends StatelessWidget {
  const _TermPicker({
    required this.offers,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });
  final List<ProOffer> offers;
  final ProTerm selected;
  final bool enabled;
  final ValueChanged<ProTerm> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    // IntrinsicHeight + stretch: the monthly cell matches the taller yearly one.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, o) in offers.indexed) ...[
            if (i > 0) const SizedBox(width: JmSpace.x2),
            Expanded(
              child: Semantics(
                button: true,
                selected: o.term == selected,
                label:
                    '${o.term.label}, ${o.price} per ${o.term.unit}${o.savings != null ? ', ${o.savings}' : ''}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled ? () => onChanged(o.term) : null,
                    borderRadius: JmRadius.mdR,
                    child: AnimatedContainer(
                      duration: JmMotion.state,
                      curve: JmMotion.ease,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      // Both cells sit on a card so the unselected one reads as a
                      // choice, not loose text on the tinted Pro card.
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: JmRadius.mdR,
                        border: Border.all(
                          color: o.term == selected ? c.ocean : c.lineStrong,
                          width: o.term == selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                o.term.label,
                                style: context.type.uiStrong.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              if (o.savings != null) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.matchTint,
                                    borderRadius: JmRadius.pillR,
                                  ),
                                  child: Text(
                                    o.savings!,
                                    style: context.type.meta.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: c.matchDeep,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${o.price} / ${o.term.unit}',
                            style: context.type.ui.copyWith(
                              fontSize: 13,
                              color: c.text,
                            ),
                          ),
                          if (o.perMonth != null)
                            Text(
                              '${o.perMonth} / month',
                              style: context.type.meta.copyWith(fontSize: 11.5),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
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
        border: Border.all(
          color: selected ? c.ocean : c.lineStrong,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
