import 'package:flutter/material.dart';

import '../../domain/clothing_analysis_service.dart';
import '../../domain/clothing_item.dart';
import '../../domain/clothing_metadata.dart';
import '../widgets/clothing_image.dart';
import '../widgets/clothing_page_layout.dart';

class ConfirmedClothingMetadata {
  const ConfirmedClothingMetadata({
    required this.category,
    required this.color,
    required this.season,
    this.subcategory,
    this.style,
  });

  final ClothingCategory category;
  final String color;
  final ClothingSeason season;
  final String? subcategory;
  final String? style;
}

class ClothingMetadataReviewScreen extends StatefulWidget {
  const ClothingMetadataReviewScreen({
    super.key,
    required this.imagePath,
    required this.analysisUnavailable,
    required this.developmentStub,
    this.suggestion,
    this.currentCategory,
    this.currentSubcategory,
    this.currentColor,
    this.currentStyle,
    this.currentSeason,
  });

  final String imagePath;
  final ClothingAnalysisSuggestion? suggestion;
  final bool analysisUnavailable;
  final bool developmentStub;
  final ClothingCategory? currentCategory;
  final String? currentSubcategory;
  final String? currentColor;
  final String? currentStyle;
  final ClothingSeason? currentSeason;

  @override
  State<ClothingMetadataReviewScreen> createState() =>
      _ClothingMetadataReviewScreenState();
}

class _ClothingMetadataReviewScreenState
    extends State<ClothingMetadataReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subcategory;
  late final TextEditingController _color;
  late final TextEditingController _style;
  late ClothingCategory? _category;
  late ClothingSeason? _season;

  String? _preferredText(String? current, String? suggested) {
    final normalizedCurrent = ClothingMetadataRules.normalizedOptionalText(
      current,
    );
    return normalizedCurrent ?? suggested;
  }

  @override
  void initState() {
    super.initState();
    final suggestion = widget.suggestion;
    _category = widget.currentCategory ?? suggestion?.category;
    _season = widget.currentSeason ?? suggestion?.season;
    _subcategory = TextEditingController(
      text: _preferredText(widget.currentSubcategory, suggestion?.subcategory),
    );
    _color = TextEditingController(
      text: _preferredText(widget.currentColor, suggestion?.color),
    );
    _style = TextEditingController(
      text: _preferredText(widget.currentStyle, suggestion?.style),
    );
  }

  @override
  void dispose() {
    _subcategory.dispose();
    _color.dispose();
    _style.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ConfirmedClothingMetadata(
        category: _category!,
        color: _color.text,
        season: _season!,
        subcategory: _subcategory.text,
        style: _style.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (message, icon) = widget.developmentStub
        ? (
            'Development stub: these are sample test values, not real AI predictions.',
            Icons.science_outlined,
          )
        : widget.analysisUnavailable
        ? (
            'Automated analysis is unavailable. Enter the metadata manually to continue.',
            Icons.info_outline,
          )
        : (
            'Review and edit every suggested value before confirming.',
            Icons.auto_awesome_outlined,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Review clothing metadata')),
      body: Form(
        key: _formKey,
        child: ClothingPageLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: AspectRatio(
                  aspectRatio: 2,
                  child: ClothingImage(
                    reference: widget.imagePath,
                    label: 'Selected clothing photo',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Expanded(child: Text(message)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ClothingCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in ClothingCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Choose a category.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subcategory,
                maxLength: ClothingMetadataRules.maxOptionalTextLength,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Subcategory (optional)',
                ),
                validator: (value) =>
                    ClothingMetadataRules.validateOptionalText(
                      value,
                      'Subcategory',
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _color,
                maxLength: 40,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (value) {
                  final color = value?.trim() ?? '';
                  if (color.isEmpty) return 'Enter a color.';
                  if (color.length > 40) {
                    return 'Color must be 40 characters or fewer.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _style,
                maxLength: ClothingMetadataRules.maxOptionalTextLength,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Style (optional)',
                ),
                validator: (value) =>
                    ClothingMetadataRules.validateOptionalText(value, 'Style'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ClothingSeason>(
                initialValue: _season,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Season'),
                items: [
                  for (final season in ClothingSeason.values)
                    DropdownMenuItem(value: season, child: Text(season.label)),
                ],
                onChanged: (value) => setState(() => _season = value),
                validator: (value) => value == null ? 'Choose a season.' : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'Size is never inferred from a photo. Enter it manually on the clothing form.',
              ),
            ],
          ),
          actions: FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check),
            label: const Text('Confirm metadata'),
          ),
        ),
      ),
    );
  }
}
