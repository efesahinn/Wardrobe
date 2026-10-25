import 'package:flutter/material.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';

class OutfitsScreen extends StatelessWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.auto_awesome_outlined,
      title: 'Outfit inspiration',
      message:
          'Outfit recommendations and Smart Quick Swap are coming soon. '
          'You can explore the Favorites placeholder below.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(favoritesRoute),
          icon: const Icon(Icons.favorite_outline),
          label: const Text('Favorites'),
        ),
      ],
    );
  }
}
