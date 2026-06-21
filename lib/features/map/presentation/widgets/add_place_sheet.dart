import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';

/// Bottom sheet for adding a new place marker.
///
/// Title, comment, and type selector.
class AddPlaceSheet extends StatefulWidget {
  const AddPlaceSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    this.prefilledTitle,
  });

  final double latitude;
  final double longitude;
  final String? prefilledTitle;

  @override
  State<AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<AddPlaceSheet> {
  final _titleCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PlaceType _type = PlaceType.other;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledTitle != null) {
      _titleCtrl.text = widget.prefilledTitle!;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<MapViewModel>();
    await vm.savePlace(
      latitude: widget.latitude,
      longitude: widget.longitude,
      title: _titleCtrl.text.trim(),
      comment: _commentCtrl.text.trim(),
      type: _type,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Place', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${widget.latitude.toStringAsFixed(6)}, '
                '${widget.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Type selector
              Text('Type', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PlaceType.values.map((t) {
                  final selected = _type == t;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          t.icon,
                          size: 16,
                          color: selected ? Colors.white : t.color,
                        ),
                        const SizedBox(width: 4),
                        Text(t.label),
                      ],
                    ),
                    selected: selected,
                    selectedColor: t.color,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Consumer<MapViewModel>(
                builder: (_, vm, _) => FilledButton(
                  onPressed: vm.isLoading ? null : _save,
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Place'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
