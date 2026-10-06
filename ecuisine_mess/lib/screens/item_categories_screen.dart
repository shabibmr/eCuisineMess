import 'package:flutter/material.dart';
import 'package:ecuisine_mess/models/item_category.dart';
import 'package:ecuisine_mess/services/api_service.dart';
import 'package:ecuisine_mess/widgets/app_form_dialog.dart';
import 'package:ecuisine_mess/widgets/master_page.dart';

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
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showAppFormDialog(
      context: context,
      title: 'Add Item Category',
      formKey: formKey,
      confirmLabel: 'Save',
      body: TextFormField(
        controller: nameCtrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'Snack',
          border: OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      return;
    }
    try {
      await _api.createItemCategory(
        categoryName: nameCtrl.text.trim(),
        sortOrder: _categories.length + 1,
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
    } finally {
      nameCtrl.dispose();
    }
  }

  Future<void> _showEditDialog(ItemCategory category) async {
    final nameCtrl = TextEditingController(text: category.categoryName);
    final sortCtrl = TextEditingController(text: '${category.sortOrder}');
    var isActive = category.isActive;
    final formKey = GlobalKey<FormState>();

    final ok = await showAppFormDialog(
      context: context,
      title: 'Edit Item Category',
      formKey: formKey,
      confirmLabel: 'Update',
      body: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sortCtrl,
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      sortCtrl.dispose();
      return;
    }

    try {
      await _api.updateItemCategory(
        id: category.id,
        categoryName: nameCtrl.text.trim(),
        sortOrder: int.parse(sortCtrl.text.trim()),
        isActive: isActive ? 1 : 0,
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
    } finally {
      nameCtrl.dispose();
      sortCtrl.dispose();
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
