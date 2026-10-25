import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: const SafeArea(
        child: EmptyState(
          icon: Icons.checkroom_outlined,
          title: 'Your wardrobe starts here',
          message:
              'Wardrobe browsing, outfit recommendations, and Smart Quick Swap '
              'are coming soon.',
        ),
      ),
    );
  }
}
