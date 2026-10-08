import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';
import 'package:ecuisine_mess/features/organizations/domain/usecases/save_organization.dart';
import 'package:ecuisine_mess/features/organizations/presentation/bloc/organization_list_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_create_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_form_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_search_field.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_switch_tile.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrganizationListPage extends StatelessWidget {
  const OrganizationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrganizationListBloc>()
        ..add(const OrganizationListStarted()),
      child: const _OrganizationListView(),
    );
  }
}

class _OrganizationListView extends StatefulWidget {
  const _OrganizationListView();

  @override
  State<_OrganizationListView> createState() => _OrganizationListViewState();
}

class _OrganizationListViewState extends State<_OrganizationListView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showOrgDialog(
    BuildContext context, {
    Organization? existing,
  }) async {
    final bloc = context.read<OrganizationListBloc>();

    final params = await showDialog<SaveOrganizationParams>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OrganizationFormDialog(existing: existing),
    );

    if (params != null && context.mounted) {
      bloc.add(OrganizationSaveRequested(params));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Organization org,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Organization',
      message: 'Are you sure you want to delete "${org.orgName}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      context
          .read<OrganizationListBloc>()
          .add(OrganizationDeleteRequested(org.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizationListBloc, OrganizationListState>(
      listener: (context, state) {
        if (state.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.notice!)),
          );
          context
              .read<OrganizationListBloc>()
              .add(const OrganizationListNoticeConsumed());
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final orgs = state.organizations;
        return MasterPage(
          title: 'Organizations',
          subtitle: 'Manage client companies, TRN, and report print headers',
          actions: [
            AppSearchField(
              controller: _searchCtrl,
              width: 240,
              hintText: 'Search org, TRN...',
              onSubmitted: (query) {
                context.read<OrganizationListBloc>().add(
                      OrganizationListStarted(search: query.trim()),
                    );
              },
              onCleared: () {
                context.read<OrganizationListBloc>().add(
                      const OrganizationListStarted(),
                    );
              },
            ),
            const SizedBox(width: 8),
            AppRefreshButton(
              onPressed: () => context
                  .read<OrganizationListBloc>()
                  .add(const OrganizationListRefreshed()),
            ),
            const SizedBox(width: 8),
            AppCreateButton(
              label: 'Add Organization',
              onPressed: () => _showOrgDialog(context),
            ),
          ],
          child: state.status == Status.loading && orgs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : orgs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No organizations found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Organization'),
                            onPressed: () => _showOrgDialog(context),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Organization')),
                            DataColumn(label: Text('TRN')),
                            DataColumn(label: Text('Currency')),
                            DataColumn(label: Text('Contact Person')),
                            DataColumn(label: Text('Phone / Email')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: orgs.map((org) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        org.orgName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (org.addressToPrint != null &&
                                          org.addressToPrint!.isNotEmpty)
                                        Text(
                                          org.addressToPrint!
                                              .split('\n')
                                              .first,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(org.trn ?? '—')),
                                DataCell(
                                  Chip(
                                    label: Text(org.currency),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                DataCell(Text(org.contactPerson ?? '—')),
                                DataCell(
                                  Text(
                                    org.phone ?? org.email ?? '—',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  AppStatusBadge.fromBool(org.isActive),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        tooltip: 'Edit',
                                        onPressed: () => _showOrgDialog(
                                          context,
                                          existing: org,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () =>
                                            _confirmDelete(context, org),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
        );
      },
    );
  }
}


class _OrganizationFormDialog extends StatefulWidget {
  const _OrganizationFormDialog({this.existing});

  final Organization? existing;

  @override
  State<_OrganizationFormDialog> createState() =>
      _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends State<_OrganizationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _trnCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _addressPrintEnCtrl;
  late final TextEditingController _addressPrintArCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _notesCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.orgName ?? '');
    _trnCtrl = TextEditingController(text: existing?.trn ?? '');
    _addressCtrl = TextEditingController(text: existing?.address ?? '');
    _addressPrintEnCtrl =
        TextEditingController(text: existing?.addressToPrint ?? '');
    _addressPrintArCtrl =
        TextEditingController(text: existing?.addressToPrintArabic ?? '');
    _currencyCtrl = TextEditingController(text: existing?.currency ?? 'AED');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    _emailCtrl = TextEditingController(text: existing?.email ?? '');
    _contactCtrl =
        TextEditingController(text: existing?.contactPerson ?? '');
    _websiteCtrl = TextEditingController(text: existing?.website ?? '');
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _trnCtrl.dispose();
    _addressCtrl.dispose();
    _addressPrintEnCtrl.dispose();
    _addressPrintArCtrl.dispose();
    _currencyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _websiteCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      SaveOrganizationParams(
        id: widget.existing?.id,
        orgName: _nameCtrl.text.trim(),
        trn: _trnCtrl.text.trim().isEmpty ? null : _trnCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        addressToPrint: _addressPrintEnCtrl.text.trim().isEmpty
            ? null
            : _addressPrintEnCtrl.text.trim(),
        addressToPrintArabic: _addressPrintArCtrl.text.trim().isEmpty
            ? null
            : _addressPrintArCtrl.text.trim(),
        currency: _currencyCtrl.text.trim().isEmpty
            ? 'AED'
            : _currencyCtrl.text.trim().toUpperCase(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim().isEmpty
            ? null
            : _contactCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AppFormDialog(
      title: isEdit ? 'Edit Organization' : 'Add Organization',
      formKey: _formKey,
      confirmLabel: isEdit ? 'Update' : 'Save',
      onConfirm: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Organization Name *',
              hintText: 'e.g. DIT UAE',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _trnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tax Registration Number (TRN)',
                    hintText: '100200300400003',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _currencyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Currency *',
                    hintText: 'AED',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressPrintEnCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Print Header Address (English)',
              hintText: 'Header address printed on reports & slips',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressPrintArCtrl,
            maxLines: 2,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'Print Header Address (Arabic)',
              hintText: 'عنوان الترويسة للتقارير والإيصالات',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _contactCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _websiteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Physical Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          AppSwitchTile(
            title: 'Active',
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }
}
