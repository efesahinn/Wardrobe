import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

class WearHistoryScreen extends StatelessWidget {
  const WearHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wear History')),
      body: const SafeArea(
        child: EmptyState(
          icon: Icons.history,
          title: 'What you wore',
          message:
              'Your final outfit choices will appear here. '
              'Wear logging is coming soon.',
        ),
      ),
    );
  }
}
