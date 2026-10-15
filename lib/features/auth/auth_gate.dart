import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../home/home_shell.dart';
import 'login_screen.dart';

/// Login na primeira abertura; o app abre se houver conta ou modo convidado.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!auth.canUseApp) {
      return const LoginScreen();
    }

    return const HomeShell();
  }
}
