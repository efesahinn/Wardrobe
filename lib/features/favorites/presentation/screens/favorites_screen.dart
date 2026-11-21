import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const SafeArea(
        child: EmptyState(
          icon: Icons.favorite_outline,
          title: 'Your favorite outfits',
          message: 'Saving and categorizing favorite outfits is coming soon.',
        ),
      ),
    );
  }
}
