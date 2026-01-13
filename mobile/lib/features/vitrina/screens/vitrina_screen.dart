import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/medals_repository.dart';

class VitrinaScreen extends StatefulWidget {
  const VitrinaScreen({super.key});

  @override
  State<VitrinaScreen> createState() => _VitrinaScreenState();
}

class _VitrinaScreenState extends State<VitrinaScreen> {
  MedalData? _medalData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedals();
  }

  Future<void> _loadMedals() async {
    try {
      final repo = context.read<MedalsRepository>();
      final data = await repo.getMedals();
      setState(() {
        _medalData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'VITRINA',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Stats header
          if (_medalData != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _StatsHeader(stats: _medalData!.stats),
              ),
            ),

          // Medals grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_medalData != null && _medalData!.medals.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final medal = _medalData!.medals[index];
                    return _MedalCard(medal: medal, index: index);
                  },
                  childCount: _medalData!.medals.length,
                ),
              ),
            )
          else
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.military_tech,
                      size: 80,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medals yet',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete games to earn medals!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final MedalStats stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.military_tech,
            value: '${stats.totalMedals}',
            label: 'Medals',
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white30,
          ),
          _StatItem(
            icon: Icons.stars,
            value: '${stats.totalPoints}',
            label: 'Points',
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white30,
          ),
          _StatItem(
            icon: Icons.games,
            value: '${stats.gamesWithMedals}',
            label: 'Games',
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: -0.2, end: 0);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryDark, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.primaryDark.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _MedalCard extends StatelessWidget {
  final Medal medal;
  final int index;

  const _MedalCard({required this.medal, required this.index});

  Color get tierColor {
    switch (medal.tier.toLowerCase()) {
      case 'gold': return AppTheme.accentGold;
      case 'silver': return const Color(0xFFC0C0C0);
      case 'bronze': return const Color(0xFFCD7F32);
      default: return AppTheme.accentNeon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Medal icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tierColor, tierColor.withOpacity(0.6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: tierColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                medal.tierEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Medal name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              medal.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          
          // Game name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              medal.gameName ?? 'Unknown Game',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          
          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${medal.points} pts',
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: index * 50), duration: 300.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}
