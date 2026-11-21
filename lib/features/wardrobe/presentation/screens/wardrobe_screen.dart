import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../data/local_image_quality_service.dart';
import '../../domain/clothing_analysis_service.dart';
import '../../domain/clothing_item.dart';
import '../../domain/wardrobe_repository.dart';
import '../gallery_image_picker.dart';
import '../widgets/clothing_image.dart';
import 'clothing_detail_screen.dart';
import 'clothing_form_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({
    super.key,
    required this.repository,
    this.pickImage = pickGalleryImage,
    this.checkImageQuality = checkLocalImageQuality,
    this.analysisService = const UnavailableClothingAnalysisService(),
  });
  final WardrobeRepository repository;
  final PickClothingImage pickImage;
  final CheckClothingImageQuality checkImageQuality;
  final ClothingAnalysisService analysisService;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<ClothingItem> _items = [];
  ClothingCategory? _category;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repository.getAll();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your wardrobe.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ClothingItem? item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<ClothingItem>(
        builder: (_) => item == null
            ? ClothingFormScreen(
                repository: widget.repository,
                pickImage: widget.pickImage,
                checkImageQuality: widget.checkImageQuality,
                analysisService: widget.analysisService,
              )
            : ClothingDetailScreen(
                item: item,
                repository: widget.repository,
                pickImage: widget.pickImage,
                checkImageQuality: widget.checkImageQuality,
                analysisService: widget.analysisService,
              ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterClothingItems(_items, _category);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = (constraints.maxWidth / (200 * scale.clamp(1, 2)))
            .floor()
            .clamp(1, 4);
        return CustomScrollView(
          key: const PageStorageKey('wardrobe-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Your digital wardrobe',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your clothing is stored locally on this device.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _open(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add clothing'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ClothingCategory>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Filter by category',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        for (final category in ClothingCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          ),
                      ],
                      onChanged: (value) => setState(() => _category = value),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: _error!,
                  message: 'Please try again.',
                  actions: [
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.checkroom_outlined,
                  title: _items.isEmpty
                      ? 'Your wardrobe is empty'
                      : 'No matching clothing',
                  message: _items.isEmpty
                      ? 'Add your first clothing item to get started.'
                      : 'Choose All or add clothing in this category.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 180 + 100 * scale,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = visible[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _open(item),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClothingImage(
                                reference: item.imageReference,
                                label: 'Photo of ${item.name}',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(item.category.label),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: visible.length),
                ),
              ),
          ],
        );
      },
    );
  }
}
