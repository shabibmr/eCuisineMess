import 'package:flutter/material.dart';
import 'package:ecuisine_mess/models/item_category.dart';
import 'package:ecuisine_mess/services/api_service.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_form_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';

class ItemCategoriesScreen extends StatefulWidget {
  const ItemCategoriesScreen({super.key});

  @override
  State<ItemCategoriesScreen> createState() => _ItemCategoriesScreenState();
}

class _ItemCategoriesScreenState extends State<ItemCategoriesScreen> {
  final ApiService _api = ApiService();
  List<ItemCategory> _categories = [];
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
      final list = await _api.fetchItemCategories(includeInactive: true);
      setState(() => _categories = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final data = await showDialog<_CategoryFormData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LegacyCategoryFormDialog(
        defaultSortOrder: _categories.length + 1,
      ),
    );
    if (data == null) return;

    try {
      await _api.createItemCategory(
        categoryName: data.name,
        sortOrder: data.sortOrder,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showEditDialog(ItemCategory category) async {
    final data = await showDialog<_CategoryFormData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LegacyCategoryFormDialog(
        category: category,
        defaultSortOrder: category.sortOrder,
      ),
    );
    if (data == null) return;

    try {
      await _api.updateItemCategory(
        id: category.id,
        categoryName: data.name,
        sortOrder: data.sortOrder,
        isActive: data.isActive ? 1 : 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterPage(
      title: 'Item Categories',
      subtitle: 'Double-click a row to edit',
      loading: _loading,
      error: _error,
      onRetry: _load,
      isEmpty: _categories.isEmpty,
      emptyMessage: 'No categories yet',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        ),
      ],
      child: Card(
        child: ListView.separated(
          itemCount: _categories.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = _categories[i];
            return InkWell(
              onDoubleTap: () => _showEditDialog(c),
              child: ListTile(
                leading: CircleAvatar(child: Text('${c.sortOrder}')),
                title: Text(c.categoryName),
                subtitle: Text(c.id, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: c.isActive
                    ? const Chip(label: Text('Active'), visualDensity: VisualDensity.compact)
                    : const Chip(label: Text('Inactive'), visualDensity: VisualDensity.compact),
              ),
            );
          },
        ),
      ),
    );
  }
}


class _CategoryFormData {
  final String name;
  final int sortOrder;
  final bool isActive;
  const _CategoryFormData({
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });
}

class _LegacyCategoryFormDialog extends StatefulWidget {
  const _LegacyCategoryFormDialog({
    this.category,
    required this.defaultSortOrder,
  });

  final ItemCategory? category;
  final int defaultSortOrder;

  @override
  State<_LegacyCategoryFormDialog> createState() =>
      _LegacyCategoryFormDialogState();
}

class _LegacyCategoryFormDialogState extends State<_LegacyCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sortCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.categoryName ?? '');
    _sortCtrl = TextEditingController(
      text: widget.category != null
          ? ''
          : '',
    );
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final sort = int.tryParse(_sortCtrl.text.trim()) ?? widget.defaultSortOrder;
    Navigator.of(context).pop(
      _CategoryFormData(
        name: _nameCtrl.text.trim(),
        sortOrder: sort,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return AppFormDialog(
      title: isEdit ? 'Edit Item Category' : 'Add Item Category',
      formKey: _formKey,
      confirmLabel: isEdit ? 'Update' : 'Save',
      onConfirm: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Snack',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sortCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sort order',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (int.tryParse(v.trim()) == null) return 'Enter a number';
              return null;
            },
          ),
          if (isEdit) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ],
      ),
    );
  }
}
