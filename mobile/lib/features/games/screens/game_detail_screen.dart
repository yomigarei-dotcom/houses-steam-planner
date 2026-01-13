import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/games_repository.dart';
import '../../../data/repositories/medals_repository.dart';

class GameDetailScreen extends StatefulWidget {
  final int appId;
  
  const GameDetailScreen({super.key, required this.appId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  GameAchievementData? _data;
  bool _isLoading = true;
  List<Medal> _newMedals = [];
  bool _showUnlocked = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final repo = context.read<GamesRepository>();
      final data = await repo.getAchievements(widget.appId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
      
      // Auto-evaluate medals if complete
      if (data.isComplete) {
        _evaluateMedals();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _evaluateMedals() async {
    try {
      final repo = context.read<MedalsRepository>();
      final newMedals = await repo.evaluateMedals(widget.appId);
      if (newMedals.isNotEmpty && mounted) {
        setState(() => _newMedals = newMedals);
        _showMedalDialog(newMedals);
      }
    } catch (e) {
      // Ignore medal errors
    }
  }

  void _showMedalDialog(List<Medal> medals) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('🏅 New Medals!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: medals.map((m) => ListTile(
            leading: Text(m.tierEmoji, style: const TextStyle(fontSize: 32)),
            title: Text(m.name),
            subtitle: Text('+${m.points} pts'),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedAchs = _data?.achievements.where((a) => a.unlocked).toList() ?? [];
    final lockedAchs = _data?.achievements.where((a) => !a.unlocked).toList() ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _data?.gameName ?? 'Loading...',
                style: const TextStyle(fontSize: 16),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_data != null)
                    CachedNetworkImage(
                      imageUrl: 'https://steamcdn-a.akamaihd.net/steam/apps/${widget.appId}/header.jpg',
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryDark.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats bar
          if (_data != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _StatsBar(data: _data!),
              ),
            ),

          // Toggle
          if (_data != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _ToggleChip(
                      label: 'Unlocked (${unlockedAchs.length})',
                      isSelected: _showUnlocked,
                      onTap: () => setState(() => _showUnlocked = true),
                    ),
                    const SizedBox(width: 8),
                    _ToggleChip(
                      label: 'Locked (${lockedAchs.length})',
                      isSelected: !_showUnlocked,
                      onTap: () => setState(() => _showUnlocked = false),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Achievements list
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_data != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final achs = _showUnlocked ? unlockedAchs : lockedAchs;
                  if (index >= achs.length) return null;
                  return _AchievementTile(
                    achievement: achs[index],
                    index: index,
                  );
                },
                childCount: (_showUnlocked ? unlockedAchs : lockedAchs).length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final GameAchievementData data;

  const _StatsBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: data.isComplete
            ? Border.all(color: AppTheme.accentNeon, width: 2)
            : null,
        boxShadow: data.isComplete
            ? AppTheme.neonGlow(AppTheme.accentNeon, intensity: 0.3)
            : null,
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 40,
            lineWidth: 6,
            percent: (data.completionPercentage / 100).clamp(0, 1),
            center: Text(
              '${data.completionPercentage.toInt()}%',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            progressColor: data.isComplete ? AppTheme.accentNeon : AppTheme.accentGold,
            backgroundColor: AppTheme.primaryMid,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Unlocked',
                        value: '${data.unlocked}',
                        color: AppTheme.accentNeon,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Locked',
                        value: '${data.locked}',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Avg Rarity',
                        value: '${data.averageRarity.toStringAsFixed(1)}%',
                        color: AppTheme.accentGold,
                      ),
                    ),
                    if (data.isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentNeon,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '100% COMPLETE',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: -0.1, end: 0);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentNeon : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final int index;

  const _AchievementTile({required this.achievement, required this.index});

  Color get rarityColor {
    if (achievement.globalPercent < 5) return const Color(0xFFFF6B6B);
    if (achievement.globalPercent < 10) return const Color(0xFFFFD93D);
    if (achievement.globalPercent < 25) return const Color(0xFF6BCB77);
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: (achievement.unlocked ? achievement.icon : achievement.iconGray) ?? '',
              width: 48,
              height: 48,
              placeholder: (_, __) => Container(
                width: 48,
                height: 48,
                color: AppTheme.primaryMid,
              ),
              errorWidget: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppTheme.primaryMid,
                child: Icon(
                  achievement.unlocked ? Icons.check_circle : Icons.lock,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          title: Text(
            achievement.displayName,
            style: TextStyle(
              color: achievement.unlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          subtitle: Text(
            achievement.hidden && !achievement.unlocked
                ? '🔒 Hidden achievement'
                : achievement.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${achievement.globalPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: rarityColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 30 * (index % 15)), duration: 200.ms);
  }
}
