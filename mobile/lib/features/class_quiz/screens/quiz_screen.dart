import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/house_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/houses_repository.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  House? _resultHouse;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final repo = context.read<HousesRepository>();
      final questions = await repo.getQuizQuestions();
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectAnswer(String house) {
    setState(() {
      _answers[_questions[_currentIndex].id] = house;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<HousesRepository>();
      final answers = _answers.entries.map((e) => {
        'questionId': e.key.toString(),
        'house': e.value,
      }).toList();
      
      final house = await repo.submitQuiz(answers);
      setState(() {
        _resultHouse = house;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_resultHouse != null) {
      return _ResultScreen(house: _resultHouse!);
    }

    final question = _questions[_currentIndex];
    final selectedHouse = _answers[question.id];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'DISCOVER YOUR CLASS',
                      style: Theme.of(context).textTheme.displaySmall,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _questions.length,
                      backgroundColor: AppTheme.primaryMid,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.accentNeon),
                    ),
                  ],
                ),
              ),

              // Question
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        question.question,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ).animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 32),

                      // Options
                      ...question.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = selectedHouse == option.house;
                        final colors = HouseColors.getByName(option.house);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectAnswer(option.house),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? colors.primary.withOpacity(0.2)
                                    : AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? colors.primary : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected ? colors.glowShadow : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: colors.gradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(colors.icon, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option.text,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: colors.primary),
                                ],
                              ),
                            ),
                          ),
                        ).animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
                          .slideX(begin: 0.1, end: 0);
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousQuestion,
                          child: const Text('Previous'),
                        ),
                      ),
                    if (_currentIndex > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentIndex == 0 ? 1 : 1,
                      child: ElevatedButton(
                        onPressed: selectedHouse != null 
                            ? (_isSubmitting ? null : _nextQuestion)
                            : null,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_currentIndex == _questions.length - 1 
                                ? 'Discover Class' 
                                : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final House house;

  const _ResultScreen({required this.house});

  @override
  Widget build(BuildContext context) {
    final colors = HouseColors.getById(house.id);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // House icon
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: colors.gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(colors.icon, color: Colors.white, size: 80),
                  ).animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),

                  const SizedBox(height: 32),

                  Text(
                    'Welcome to',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 8),

                  Text(
                    house.name.toUpperCase(),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: colors.primary,
                      letterSpacing: 4,
                    ),
                  ).animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

                  const SizedBox(height: 8),

                  Text(
                    house.archetype,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ).animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  Text(
                    house.description ?? 'Your journey begins now!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate()
                    .fadeIn(delay: 1000.ms, duration: 400.ms),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/house-cup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                      ),
                      child: const Text(
                        'Enter the Arena',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 1200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
