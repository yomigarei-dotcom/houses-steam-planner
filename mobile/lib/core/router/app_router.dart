import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/house_cup/screens/house_cup_screen.dart';
import '../../features/vitrina/screens/vitrina_screen.dart';
import '../../features/games/screens/games_screen.dart';
import '../../features/games/screens/game_detail_screen.dart';
import '../../features/class_quiz/screens/quiz_screen.dart';
import '../../features/planner/screens/planner_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => '/house-cup',
          ),
          GoRoute(
            path: '/house-cup',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HouseCupScreen(),
            ),
          ),
          GoRoute(
            path: '/vitrina',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VitrinaScreen(),
            ),
          ),
          GoRoute(
            path: '/games',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GamesScreen(),
            ),
          ),
          GoRoute(
            path: '/planner',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlannerScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/game/:appId',
        builder: (context, state) {
          final appId = int.parse(state.pathParameters['appId']!);
          return GameDetailScreen(appId: appId);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isLoggedIn = authState is Authenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';

      if (isSplash) return null;
      
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        // Check if user needs to take quiz
        final user = (authState as Authenticated).user;
        if (!user.hasHouse) {
          return '/quiz';
        }
        return '/house-cup';
      }

      return null;
    },
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      final authBloc = context.read<AuthBloc>();
      authBloc.stream.listen((state) {
        if (state is Authenticated) {
          if (!state.user.hasHouse) {
            context.go('/quiz');
          } else {
            context.go('/house-cup');
          }
        } else if (state is Unauthenticated) {
          context.go('/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'SteamPlanner',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
