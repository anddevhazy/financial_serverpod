import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              decoration: BoxDecoration(
                color: Palette.sheet,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.rule),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fine Man', style: Fonts.display(40)),
                  const SizedBox(height: 4),
                  const DoubleRule(width: 120),
                  const SizedBox(height: 20),
                  Text(
                    'Sign in to keep your tables saved and in sync across devices.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Palette.muted),
                  ),
                  const SizedBox(height: 24),
                  SignInWidget(
                    client: client,
                    onError: (error) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sign-in failed. Try again. ($error)',
                            ),
                          ),
                        );
                    },
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
