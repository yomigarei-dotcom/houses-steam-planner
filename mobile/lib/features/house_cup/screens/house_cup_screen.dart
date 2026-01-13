import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/house_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/houses_repository.dart';
import '../../auth/bloc/auth_bloc.dart';

class HouseCupScreen extends StatefulWidget {
  const HouseCupScreen({super.key});

  @override
  State<HouseCupScreen> createState() => _HouseCupScreenState();
}

class _HouseCupScreenState extends State<HouseCupScreen> {
  bool _showSeasonPoints = false;
  HouseCupData? _cupData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<HousesRepository>();
      final data = await repo.getHouseCup();
      setState(() {
        _cupData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'HOUSE CUP',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
            ],
          ),

          // Toggle buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'General',
                      isSelected: !_showSeasonPoints,
                      onTap: () => setState(() => _showSeasonPoints = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Season',
                      isSelected: _showSeasonPoints,
                      onTap: () => setState(() => _showSeasonPoints = true),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // House standings
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_cupData != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final standings = _showSeasonPoints && _cupData!.seasonStandings != null
                      ? _cupData!.seasonStandings!
                      : _cupData!.generalStandings;
                  
                  if (index >= standings.length) return null;
                  
                  final house = standings[index];
                  final colors = HouseColors.getById(house.id);
                  final maxPoints = standings.first.totalPoints.toDouble();
                  final percent = maxPoints > 0 ? house.totalPoints / maxPoints : 0.0;
                  final isUserHouse = user?.houseId == house.id;

                  return _HouseCard(
                    house: house,
                    colors: colors,
                    percent: percent,
                    rank: index + 1,
                    isUserHouse: isUserHouse,
                    delay: index * 100,
                  );
                },
                childCount: 4,
              ),
            ),

          // User stats card
          if (user != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _UserStatsCard(user: user),
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

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentNeon : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentNeon : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HouseCard extends StatelessWidget {
  final House house;
  final HouseColorPalette colors;
  final double percent;
  final int rank;
  final bool isUserHouse;
  final int delay;

  const _HouseCard({
    required this.house,
    required this.colors,
    required this.percent,
    required this.rank,
    required this.isUserHouse,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: isUserHouse
              ? Border.all(color: colors.primary, width: 2)
              : null,
          boxShadow: isUserHouse ? colors.glowShadow : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: rank == 1 ? AppTheme.goldGradient : null,
                  color: rank == 1 ? null : AppTheme.primaryMid,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rank == 1 ? AppTheme.primaryDark : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // House icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: colors.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(colors.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),

              // House info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      house.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      house.archetype,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      lineHeight: 8,
                      percent: percent.clamp(0, 1),
                      backgroundColor: AppTheme.primaryMid,
                      linearGradient: colors.gradient,
                      barRadius: const Radius.circular(4),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${house.totalPoints}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  Text(
                    'pts',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
      .slideX(begin: 0.1, end: 0);
  }
}

class _UserStatsCard extends StatelessWidget {
  final User user;

  const _UserStatsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final houseColors = user.houseId != null 
        ? HouseColors.getById(user.houseId!) 
        : HouseColors.achiever;

    return Container(
      decoration: BoxDecoration(
        gradient: houseColors.gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  user.houseName ?? 'No House',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.generalPoints}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                'Total Points',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 500.ms, duration: 400.ms)
      .slideY(begin: 0.2, end: 0);
  }
}
