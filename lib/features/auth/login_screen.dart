import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/auth_controller.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AuthController>();
    final c = context.jm;
    return AuthScaffold(
      title: 'Welcome back',
      lede: 'Sign in to pick up your shortlist.',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthFooterLink(
            question: 'New here?',
            action: 'Create an account',
            onPressed: ctrl.busy ? null : () => context.go(AppRoutes.register),
          ),
          const SizedBox(height: JmSpace.x1),
          const AppVersionLabel(),
        ],
      ),
      children: [
        TextField(
          controller: ctrl.email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: JmSpace.x3),
        TextField(
          controller: ctrl.password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => ctrl.login(),
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: JmSpace.x1),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: ctrl.busy ? null : () => context.push(AppRoutes.forgotPassword),
            style: TextButton.styleFrom(
              foregroundColor: c.muted,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Forgot password?'),
          ),
        ),
        if (ctrl.error != null) ...[const SizedBox(height: JmSpace.x2), ErrorLine(ctrl.error!)],
        const SizedBox(height: JmSpace.x3),
        PrimaryButton(label: 'Sign in', busyLabel: 'Signing in…', busy: ctrl.busy, large: true, onPressed: ctrl.login),
        const SizedBox(height: JmSpace.x4),
        const OrDivider(),
        const SizedBox(height: JmSpace.x4),
        GoogleButton(onPressed: ctrl.busy ? null : ctrl.continueWithGoogle),
        if (showAppleSignIn) ...[
          const SizedBox(height: JmSpace.x2),
          AppleButton(onPressed: ctrl.busy ? null : ctrl.continueWithApple),
        ],
      ],
    );
  }
}
