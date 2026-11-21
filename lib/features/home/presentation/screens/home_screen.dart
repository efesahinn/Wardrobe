import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.home_outlined,
      title: 'Your wardrobe starts here',
      message:
          'Wardrobe browsing, outfit recommendations, and Smart Quick Swap '
          'are coming soon.',
    );
  }
}
