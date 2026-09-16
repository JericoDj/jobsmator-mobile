import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/auth_controller.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import 'widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AuthController>();
    final c = context.jm;
    void back() => context.canPop() ? context.pop() : context.go(AppRoutes.login);

    return AuthScaffold(
      onBack: back,
      title: ctrl.done ? 'Check your inbox' : 'Reset your password',
      lede: ctrl.done
          ? 'We sent a link to ${ctrl.email.text.trim()}. It expires in an hour.'
          : "Enter your email and we'll send a link to set a new one.",
      children: ctrl.done
          ? [
              Container(
                padding: const EdgeInsets.all(JmSpace.x4),
                decoration: BoxDecoration(color: c.matchTint, borderRadius: JmRadius.mdR),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, color: c.matchDeep),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Didn't get it? Check spam, or try again in a minute.",
                        style: context.type.meta.copyWith(color: c.matchDeep),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: JmSpace.x6),
              PrimaryButton(label: 'Back to sign in', large: true, onPressed: back),
            ]
          : [
              TextField(
                controller: ctrl.email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => ctrl.sendReset(),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              if (ctrl.error != null) ...[const SizedBox(height: JmSpace.x3), ErrorLine(ctrl.error!)],
              const SizedBox(height: JmSpace.x4),
              PrimaryButton(
                label: 'Send reset link',
                busyLabel: 'Sending…',
                busy: ctrl.busy,
                large: true,
                onPressed: ctrl.sendReset,
              ),
            ],
    );
  }
}
