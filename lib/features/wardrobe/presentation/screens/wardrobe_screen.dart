import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.checkroom_outlined,
      title: 'Your digital wardrobe',
      message:
          'Your clothing collection will appear here. '
          'Adding and managing garments is coming soon.',
    );
  }
}
