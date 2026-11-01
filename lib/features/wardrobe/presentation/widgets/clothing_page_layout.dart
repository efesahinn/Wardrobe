import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps actions at the bottom when content fits, without flex children inside
/// an unbounded scroll view. All form fields stay mounted for validation.
class ClothingPageLayout extends StatelessWidget {
  const ClothingPageLayout({
    super.key,
    required this.content,
    required this.actions,
  });

  final Widget content;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 608,
                minHeight: math.max(0, viewport.maxHeight - 32),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
