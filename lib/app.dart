import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

class WardrobeApp extends StatelessWidget {
  const WardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: homeRoute,
      routes: appRoutes,
    );
  }
}
