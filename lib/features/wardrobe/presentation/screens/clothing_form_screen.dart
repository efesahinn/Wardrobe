import 'package:flutter/material.dart';

import '../../domain/clothing_item.dart';
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
    _category = item?.category;
    _season = item?.season;
    _image = item?.imageReference;
  }

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    super.dispose();
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
          imageReference: _image,
        );
      } else {
        saved = ClothingItem(
          id: existing.id,
          name: _name.text.trim(),
          category: _category!,
          color: _color.text.trim(),
          season: _season!,
          imageReference: _image,
        );
        await widget.repository.update(saved);
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
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _category = value),
                  validator: (value) =>
                      value == null ? 'Choose a category.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _color,
                  textInputAction: TextInputAction.done,
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
