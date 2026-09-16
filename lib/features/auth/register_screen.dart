import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/auth_controller.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AuthController>();
    final c = context.jm;
    return AuthScaffold(
      title: 'Create your account',
      lede: 'Free to start. Your resume stays private to you.',
      footer: AuthFooterLink(
        question: 'Have an account?',
        action: 'Sign in',
        onPressed: ctrl.busy ? null : () => context.go(AppRoutes.login),
      ),
      children: [
        TextField(
          controller: ctrl.name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: JmSpace.x3),
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
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => ctrl.register(),
          decoration: const InputDecoration(labelText: 'Password', hintText: 'At least 8 characters'),
        ),
        if (ctrl.error != null) ...[const SizedBox(height: JmSpace.x3), ErrorLine(ctrl.error!)],
        const SizedBox(height: JmSpace.x4),
        PrimaryButton(
          label: 'Create account',
          busyLabel: 'Creating…',
          busy: ctrl.busy,
          large: true,
          onPressed: ctrl.register,
        ),
        const SizedBox(height: JmSpace.x3),
        Text(
          'By continuing you agree to the Terms and Privacy Policy.',
          style: context.type.meta.copyWith(color: c.faint),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: JmSpace.x4),
        const OrDivider(),
        const SizedBox(height: JmSpace.x4),
        GoogleButton(onPressed: ctrl.busy ? null : ctrl.continueWithGoogle, label: 'Sign up with Google'),
        if (showAppleSignIn) ...[
          const SizedBox(height: JmSpace.x2),
          AppleButton(onPressed: ctrl.busy ? null : ctrl.continueWithApple, label: 'Sign up with Apple'),
        ],
      ],
    );
  }
}
