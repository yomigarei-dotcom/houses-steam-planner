import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is LoginUrlReady) {
          final uri = Uri.parse(state.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Logo & Title
                  Icon(
                    Icons.emoji_events,
                    size: 100,
                    color: AppTheme.accentGold,
                  ).animate()
                    .fadeIn(duration: 600.ms)
                    .scale(delay: 200.ms),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'STEAMPLANNER',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      letterSpacing: 4,
                    ),
                  ).animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'The Ultimate Achievement Tracker',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ).animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),
                  
                  const SizedBox(height: 48),
                  
                  // House preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HouseIcon(icon: Icons.emoji_events, color: const Color(0xFFFFD700), delay: 600),
                      _HouseIcon(icon: Icons.explore, color: const Color(0xFF20B2AA), delay: 700),
                      _HouseIcon(icon: Icons.groups, color: const Color(0xFFDC143C), delay: 800),
                      _HouseIcon(icon: Icons.military_tech, color: const Color(0xFF39FF14), delay: 900),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Choose Your Class. Earn Medals. Win the Cup.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms),
                  
                  const Spacer(),
                  
                  // Login Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: isLoading 
                            ? null 
                            : () => context.read<AuthBloc>().add(LoginRequested()),
                          icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                          label: Text(
                            isLoading ? 'Connecting...' : 'Login with Steam',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate()
                        .fadeIn(delay: 1200.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Secure login via Steam OpenID',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HouseIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int delay;

  const _HouseIcon({
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1));
  }
}
