import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/token_storage.dart';
import 'package:muarra_app_v1/features/auth/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final token = await TokenStorage.getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      context.go('/signin');
      return;
    }

    try {
      await AuthService().checkAuth();

      if (!mounted) return;

      context.go('/home');
    } catch (_) {
      await TokenStorage.deleteToken();

      if (!mounted) return;

      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
