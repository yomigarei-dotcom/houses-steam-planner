import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/games_repository.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  List<Game> _games = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _filter = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGames({bool forceRefresh = false}) async {
    try {
      final repo = context.read<GamesRepository>();
      final games = await repo.getGames(forceRefresh: forceRefresh);
      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncLibrary() async {
    setState(() => _isSyncing = true);
    try {
      final repo = context.read<GamesRepository>();
      await repo.syncLibrary();
      await _loadGames(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: ${e.toString()}')),
        );
      }
    }
    setState(() => _isSyncing = false);
  }

  List<Game> get _filteredGames {
    switch (_filter) {
      case 'complete':
        return _games.where((g) => g.isComplete).toList();
      case 'inProgress':
        return _games.where((g) => g.hasAchievements && !g.isComplete && g.achievementsUnlocked > 0).toList();
      case 'notStarted':
        return _games.where((g) => g.hasAchievements && g.achievementsUnlocked == 0).toList();
      default:
        return _games.where((g) => g.hasAchievements).toList();
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
                'GAMES',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                onPressed: _isSyncing ? null : _syncLibrary,
              ),
            ],
          ),

          // Filter tabs
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.primaryDark,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.accentNeon,
                labelColor: AppTheme.accentNeon,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Complete'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Not Started'),
                ],
                onTap: (index) {
                  setState(() {
                    _filter = ['all', 'complete', 'inProgress', 'notStarted'][index];
                  });
                },
              ),
            ),
          ),

          // Stats summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _GameStats(games: _games),
            ),
          ),

          // Games list
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final games = _filteredGames;
                  if (index >= games.length) return null;
                  return _GameCard(
                    game: games[index],
                    onTap: () => context.push('/game/${games[index].appId}'),
                    index: index,
                  );
                },
                childCount: _filteredGames.length,
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

class _GameStats extends StatelessWidget {
  final List<Game> games;

  const _GameStats({required this.games});

  @override
  Widget build(BuildContext context) {
    final withAchievements = games.where((g) => g.hasAchievements).toList();
    final complete = withAchievements.where((g) => g.isComplete).length;
    final totalAch = withAchievements.fold<int>(0, (s, g) => s + g.achievementsTotal);
    final unlockedAch = withAchievements.fold<int>(0, (s, g) => s + g.achievementsUnlocked);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Games',
            value: '${withAchievements.length}',
            color: AppTheme.accentCyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Complete',
            value: '$complete',
            color: AppTheme.accentNeon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Achievements',
            value: '$unlockedAch/$totalAch',
            color: AppTheme.accentGold,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  final int index;

  const _GameCard({
    required this.game,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final percent = game.achievementsTotal > 0
        ? game.achievementsUnlocked / game.achievementsTotal
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: game.isComplete
                ? Border.all(color: AppTheme.accentNeon.withOpacity(0.5), width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Game image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: game.headerUrl ?? '',
                  width: 120,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 120,
                    height: 80,
                    color: AppTheme.primaryMid,
                    child: const Icon(Icons.games, color: AppTheme.textSecondary),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 120,
                    height: 80,
                    color: AppTheme.primaryMid,
                    child: const Icon(Icons.games, color: AppTheme.textSecondary),
                  ),
                ),
              ),

              // Game info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.progressText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: AppTheme.primaryMid,
                        valueColor: AlwaysStoppedAnimation(
                          game.isComplete ? AppTheme.accentNeon : AppTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Completion indicator
              Padding(
                padding: const EdgeInsets.all(12),
                child: CircularPercentIndicator(
                  radius: 25,
                  lineWidth: 4,
                  percent: percent.clamp(0, 1),
                  center: Text(
                    '${game.completionPercentage.toInt()}%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  progressColor: game.isComplete ? AppTheme.accentNeon : AppTheme.accentGold,
                  backgroundColor: AppTheme.primaryMid,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 50 * (index % 10)), duration: 300.ms)
      .slideX(begin: 0.1, end: 0);
  }
}
