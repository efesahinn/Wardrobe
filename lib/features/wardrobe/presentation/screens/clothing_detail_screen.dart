import 'package:flutter/material.dart';

import '../../data/local_image_quality_service.dart';
import '../../domain/clothing_analysis_service.dart';
import '../../domain/clothing_item.dart';
import '../../domain/wardrobe_repository.dart';
import '../gallery_image_picker.dart';
import '../widgets/clothing_image.dart';
import '../widgets/clothing_page_layout.dart';
import 'clothing_form_screen.dart';

class ClothingDetailScreen extends StatefulWidget {
  const ClothingDetailScreen({
    super.key,
    required this.item,
    required this.repository,
    this.pickImage = pickGalleryImage,
    this.checkImageQuality = checkLocalImageQuality,
    this.analysisService = const UnavailableClothingAnalysisService(),
  });
  final ClothingItem item;
  final WardrobeRepository repository;
  final PickClothingImage pickImage;
  final CheckClothingImageQuality checkImageQuality;
  final ClothingAnalysisService analysisService;

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  late ClothingItem _item = widget.item;
  bool _deleting = false;

  String _metadataValue(String? value) =>
      value == null || value.trim().isEmpty ? 'Not specified' : value;

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<ClothingItem>(
      MaterialPageRoute(
        builder: (_) => ClothingFormScreen(
          repository: widget.repository,
          item: _item,
          pickImage: widget.pickImage,
          checkImageQuality: widget.checkImageQuality,
          analysisService: widget.analysisService,
        ),
      ),
    );
    if (mounted && updated != null) setState(() => _item = updated);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete clothing?'),
        content: Text('Remove "${_item.name}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.repository.delete(_item.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this item. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clothing details')),
      body: ClothingPageLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: ClothingImage(
                  reference: _item.imageReference,
                  label: 'Photo of ${_item.name}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                _item.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            Text('Category: ${_item.category.label}'),
            Text('Subcategory: ${_metadataValue(_item.subcategory)}'),
            Text('Style: ${_metadataValue(_item.style)}'),
            Text('Size: ${_metadataValue(_item.size)}'),
            Text('Color: ${_item.color}'),
            Text('Season: ${_item.season.label}'),
          ],
        ),
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _deleting ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit clothing'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _deleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(_deleting ? 'Deleting…' : 'Delete clothing'),
            ),
          ],
        ),
      ),
    );
  }
}
