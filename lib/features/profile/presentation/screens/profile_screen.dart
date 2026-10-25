import 'package:flutter/material.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.person_outline,
      title: 'Your profile',
      message:
          'Account details and preferences are coming soon. '
          'You can explore the Wear History placeholder below.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(wearHistoryRoute),
          icon: const Icon(Icons.history),
          label: const Text('Wear History'),
        ),
      ],
    );
  }
}
