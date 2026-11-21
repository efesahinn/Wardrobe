import 'package:flutter/material.dart';

import '../../domain/clothing_item.dart';
import '../../domain/clothing_metadata.dart';
import '../../domain/wardrobe_repository.dart';
import '../gallery_image_picker.dart';
import '../widgets/clothing_image.dart';
import '../widgets/clothing_page_layout.dart';

class ClothingFormScreen extends StatefulWidget {
  const ClothingFormScreen({
    super.key,
    required this.repository,
    this.item,
    this.pickImage = pickGalleryImage,
  });
  final WardrobeRepository repository;
  final ClothingItem? item;
  final PickClothingImage pickImage;

  @override
  State<ClothingFormScreen> createState() => _ClothingFormScreenState();
}

class _ClothingFormScreenState extends State<ClothingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _color;
  late final TextEditingController _size;
  late final TextEditingController _subcategory;
  late final TextEditingController _style;
  ClothingCategory? _category;
  ClothingSeason? _season;
  String? _image;
  String? _error;
  bool _saving = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name);
    _color = TextEditingController(text: item?.color);
    _size = TextEditingController(text: item?.size);
    _subcategory = TextEditingController(text: item?.subcategory);
    _style = TextEditingController(text: item?.style);
    _category = item?.category;
    _season = item?.season;
    _image = item?.imageReference;
  }

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    _size.dispose();
    _subcategory.dispose();
    _style.dispose();
    super.dispose();
  }

  void _setCategory(ClothingCategory? category) {
    if (category != null &&
        ClothingMetadataRules.validateSize(category, _size.text) != null) {
      _size.clear();
    }
    setState(() => _category = category);
  }

  Widget _buildSizeField(bool busy) {
    final category = _category;
    if (category?.sizeInputType == ClothingSizeInputType.alpha) {
      final normalized = ClothingMetadataRules.normalizedSize(
        category!,
        _size.text,
      );
      final selected = ClothingMetadataRules.topSizes.contains(normalized)
          ? normalized!
          : '';
      return DropdownButtonFormField<String>(
        key: ValueKey('size-${category.name}'),
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Size (optional)'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Not specified')),
          for (final size in ClothingMetadataRules.topSizes)
            DropdownMenuItem(value: size, child: Text(size)),
        ],
        onChanged: busy
            ? null
            : (value) => setState(() => _size.text = value ?? ''),
        validator: (value) =>
            ClothingMetadataRules.validateSize(category, value),
      );
    }

    final (hint, keyboardType) = switch (category?.sizeInputType) {
      ClothingSizeInputType.bottoms => (
        'Examples: 32 or W32/L34',
        TextInputType.text,
      ),
      ClothingSizeInputType.euShoes => (
        'EU size, for example 42 or 42.5',
        const TextInputType.numberWithOptions(decimal: true),
      ),
      _ => ('Enter a size if applicable', TextInputType.text),
    };
    return TextFormField(
      key: ValueKey('size-${category?.name ?? 'none'}'),
      controller: _size,
      enabled: !busy,
      maxLength: ClothingMetadataRules.maxSizeLength,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: 'Size (optional)', hintText: hint),
      validator: (value) => category == null
          ? null
          : ClothingMetadataRules.validateSize(category, value),
    );
  }

  Future<void> _selectImage() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final path = await widget.pickImage();
      if (mounted && path != null) setState(() => _image = path);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not open the gallery. Check photo access and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.item;
      final ClothingItem saved;
      if (existing == null) {
        saved = await widget.repository.create(
          name: _name.text.trim(),
          category: _category!,
          color: _color.text.trim(),
          season: _season!,
          size: _size.text,
          subcategory: _subcategory.text,
          style: _style.text,
          imageReference: _image,
        );
      } else {
        final updated = ClothingItem(
          id: existing.id,
          name: _name.text.trim(),
          category: _category!,
          color: _color.text.trim(),
          season: _season!,
          size: _size.text,
          subcategory: _subcategory.text,
          style: _style.text,
          imageReference: _image,
        );
        await widget.repository.update(updated);
        saved =
            await widget.repository.getById(existing.id) ??
            (throw StateError('Updated clothing item not found.'));
      }
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save this item. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _picking;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.item == null ? 'Add clothing' : 'Edit clothing'),
        ),
        resizeToAvoidBottomInset: true,
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
                      reference: _image,
                      label: 'Clothing photo preview',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : _selectImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _picking ? 'Opening gallery…' : 'Choose gallery image',
                  ),
                ),
                if (_image != null)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _image = null),
                    child: const Text('Remove image'),
                  ),
                const Text('Photo optional. A plain background works best.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  enabled: !busy,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a clothing name.'
                      : null,
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
                  onChanged: busy ? null : _setCategory,
                  validator: (value) =>
                      value == null ? 'Choose a category.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subcategory,
                  enabled: !busy,
                  maxLength: ClothingMetadataRules.maxOptionalTextLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory (optional)',
                    hintText: 'For example, T-shirt or chinos',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      ClothingMetadataRules.validateOptionalText(
                        value,
                        'Subcategory',
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _style,
                  enabled: !busy,
                  maxLength: ClothingMetadataRules.maxOptionalTextLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Style (optional)',
                    hintText: 'For example, Casual or Business',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      ClothingMetadataRules.validateOptionalText(
                        value,
                        'Style',
                      ),
                ),
                const SizedBox(height: 16),
                _buildSizeField(busy),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _color,
                  textInputAction: TextInputAction.next,
                  enabled: !busy,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Color'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a color.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ClothingSeason>(
                  initialValue: _season,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Season'),
                  items: [
                    for (final season in ClothingSeason.values)
                      DropdownMenuItem(
                        value: season,
                        child: Text(season.label),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _season = value),
                  validator: (value) =>
                      value == null ? 'Choose a season.' : null,
                ),
              ],
            ),
            actions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: busy ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save clothing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
