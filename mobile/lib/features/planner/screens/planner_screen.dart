import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/house_colors.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  int _selectedDay = DateTime.now().weekday - 1; // 0-indexed

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  // Example schedule data
  static final _schedule = {
    0: [
      _ScheduleBlock('Achiever Training', 'Complete near-100% games', 45, HouseColors.achiever),
      _ScheduleBlock('Explorer Lab', 'Try a new genre', 30, HouseColors.explorer),
    ],
    1: [
      _ScheduleBlock('Killer Arena', 'Hunt rare achievements', 60, HouseColors.killer),
    ],
    2: [
      _ScheduleBlock('Socializer Club', 'Co-op with friends', 90, HouseColors.socializer),
    ],
    3: [
      _ScheduleBlock('Achiever Training', 'Focus on completions', 45, HouseColors.achiever),
    ],
    4: [
      _ScheduleBlock('Free Play', 'Your choice!', 60, null),
    ],
    5: [
      _ScheduleBlock('Marathon Session', 'Big game push', 120, HouseColors.achiever),
      _ScheduleBlock('Killer Challenge', 'Speed 100%', 60, HouseColors.killer),
    ],
    6: [
      _ScheduleBlock('Rest Day', 'Recharge for the week', 0, null),
    ],
  };

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
                'PLANNER',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Day selector
          SliverToBoxAdapter(
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final isSelected = _selectedDay == index;
                  final isToday = index == DateTime.now().weekday - 1;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentNeon : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected
                            ? Border.all(color: AppTheme.accentNeon)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _days[index],
                            style: TextStyle(
                              color: isSelected 
                                  ? AppTheme.primaryDark 
                                  : AppTheme.textSecondary,
                              fontWeight: isSelected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppTheme.primaryDark 
                                    : AppTheme.accentNeon,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Today's stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _TodayStats(blocks: _schedule[_selectedDay] ?? []),
            ),
          ),

          // Schedule blocks
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Today\'s Schedule',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          if (_schedule[_selectedDay]?.isEmpty ?? true)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No sessions planned',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final blocks = _schedule[_selectedDay]!;
                  if (index >= blocks.length) return null;
                  return _ScheduleCard(
                    block: blocks[index],
                    index: index,
                  );
                },
                childCount: _schedule[_selectedDay]?.length ?? 0,
              ),
            ),

          // Add session button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Add session dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon: Add custom sessions!')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Session'),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  final List<_ScheduleBlock> blocks;

  const _TodayStats({required this.blocks});

  @override
  Widget build(BuildContext context) {
    final totalMinutes = blocks.fold<int>(0, (sum, b) => sum + b.durationMinutes);
    final sessionsCount = blocks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '$sessionsCount',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.accentNeon,
                  ),
                ),
                Text(
                  'Sessions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.primaryMid,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${totalMinutes}m',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.accentGold,
                  ),
                ),
                Text(
                  'Total Time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final _ScheduleBlock block;
  final int index;

  const _ScheduleCard({required this.block, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = block.house;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: colors != null
              ? Border.all(color: colors.primary.withOpacity(0.5), width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: colors?.gradient,
                  color: colors == null ? AppTheme.primaryMid : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  colors?.icon ?? Icons.sports_esports,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      block.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Duration
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (colors?.primary ?? AppTheme.textSecondary).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  block.durationMinutes > 0 ? '${block.durationMinutes}m' : '—',
                  style: TextStyle(
                    color: colors?.primary ?? AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
      .slideX(begin: 0.1, end: 0);
  }
}

class _ScheduleBlock {
  final String title;
  final String description;
  final int durationMinutes;
  final HouseColorPalette? house;

  const _ScheduleBlock(this.title, this.description, this.durationMinutes, this.house);
}
