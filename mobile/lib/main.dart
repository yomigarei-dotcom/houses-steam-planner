import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/games_repository.dart';
import 'data/repositories/medals_repository.dart';
import 'data/repositories/houses_repository.dart';
import 'data/local/database_helper.dart';
import 'data/remote/api_service.dart';
import 'features/auth/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseHelper.instance.database;
  
  runApp(const SteamPlannerApp());
}

class SteamPlannerApp extends StatelessWidget {
  const SteamPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(create: (ctx) => AuthRepository(ctx.read<ApiService>())),
        RepositoryProvider(create: (ctx) => GamesRepository(ctx.read<ApiService>())),
        RepositoryProvider(create: (ctx) => MedalsRepository(ctx.read<ApiService>())),
        RepositoryProvider(create: (ctx) => HousesRepository(ctx.read<ApiService>())),
      ],
      child: BlocProvider(
        create: (ctx) => AuthBloc(ctx.read<AuthRepository>())..add(CheckAuthStatus()),
        child: MaterialApp.router(
          title: 'SteamPlanner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
