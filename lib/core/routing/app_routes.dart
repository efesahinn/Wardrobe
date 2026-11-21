import 'package:flutter/material.dart';

import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/wardrobe/domain/wardrobe_repository.dart';
import '../../features/wear_history/presentation/screens/wear_history_screen.dart';
import 'app_shell.dart';
import 'route_paths.dart';

export 'route_paths.dart';

Map<String, WidgetBuilder> buildAppRoutes({
  WardrobeRepository? wardrobeRepository,
}) => {
  homeRoute: (context) => AppShell(wardrobeRepository: wardrobeRepository),
  favoritesRoute: (context) => const FavoritesScreen(),
  wearHistoryRoute: (context) => const WearHistoryScreen(),
};
