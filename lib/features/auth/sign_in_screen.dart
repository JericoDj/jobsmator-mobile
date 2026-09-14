import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('JobsMator', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('Resume in. Ranked jobs out.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              FilledButton(onPressed: auth.signInWithGoogle, child: const Text('Continue with Google')),
            ],
          ),
        ),
      ),
    );
  }
}
