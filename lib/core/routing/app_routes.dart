import 'package:flutter/material.dart';

import '../../features/wardrobe/presentation/screens/home_screen.dart';

const homeRoute = '/';

final Map<String, WidgetBuilder> appRoutes = {
  homeRoute: (context) => const HomeScreen(),
};
