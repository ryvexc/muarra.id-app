import 'package:go_router/go_router.dart';
import 'package:muarra_app_v1/pages/home_page.dart';
import 'package:muarra_app_v1/pages/splash_page.dart';

import '../pages/auth/signin_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(
      path: '/signin',
      name: 'signin',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
