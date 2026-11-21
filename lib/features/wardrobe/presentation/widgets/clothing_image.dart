import 'dart:io';

import 'package:flutter/material.dart';

/// Fits the whole photo into its responsive frame without changing its ratio.
class ClothingImage extends StatelessWidget {
  const ClothingImage({
    super.key,
    required this.reference,
    required this.label,
  });
  final String? reference;
  final String label;

  @override
  Widget build(BuildContext context) {
    final placeholder = const Center(
      child: Icon(Icons.checkroom_outlined, size: 48),
    );
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: ColoredBox(
          // Letterboxing keeps portrait, landscape, and square photos intact.
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade200,
          child: reference == null
              ? placeholder
              : Image.file(
                  File(reference!),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  width: double.infinity,
                  errorBuilder: (context, error, stack) => placeholder,
                ),
        ),
      ),
    );
  }
}
