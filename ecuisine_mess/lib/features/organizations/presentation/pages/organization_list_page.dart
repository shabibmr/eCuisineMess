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
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: existing?.orgName ?? '');
    final trnCtrl = TextEditingController(text: existing?.trn ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final addressPrintEnCtrl =
        TextEditingController(text: existing?.addressToPrint ?? '');
    final addressPrintArCtrl =
        TextEditingController(text: existing?.addressToPrintArabic ?? '');
    final currencyCtrl =
        TextEditingController(text: existing?.currency ?? 'AED');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final contactCtrl =
        TextEditingController(text: existing?.contactPerson ?? '');
    final websiteCtrl = TextEditingController(text: existing?.website ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var isActive = existing?.isActive ?? true;

    final isEdit = existing != null;

    final ok = await showAppFormDialog(
      context: context,
      title: isEdit ? 'Edit Organization' : 'Add Organization',
      formKey: formKey,
      confirmLabel: isEdit ? 'Update' : 'Save',
      body: StatefulBuilder(
        builder: (ctx, setLocal) {
          return SingleChildScrollView(
            child: SizedBox(
              width: 540,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameCtrl,
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
                          controller: trnCtrl,
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
                          controller: currencyCtrl,
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
                    controller: addressPrintEnCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Print Header Address (English)',
                      hintText: 'Header address printed on reports & slips',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressPrintArCtrl,
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
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: contactCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: websiteCtrl,
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
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Physical Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppSwitchTile(
                    title: 'Active',
                    value: isActive,
                    onChanged: (v) => setLocal(() => isActive = v),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (ok == true) {
      bloc.add(
        OrganizationSaveRequested(
          SaveOrganizationParams(
            id: existing?.id,
            orgName: nameCtrl.text.trim(),
            trn: trnCtrl.text.trim().isEmpty ? null : trnCtrl.text.trim(),
            address: addressCtrl.text.trim().isEmpty
                ? null
                : addressCtrl.text.trim(),
            addressToPrint: addressPrintEnCtrl.text.trim().isEmpty
                ? null
                : addressPrintEnCtrl.text.trim(),
            addressToPrintArabic: addressPrintArCtrl.text.trim().isEmpty
                ? null
                : addressPrintArCtrl.text.trim(),
            currency: currencyCtrl.text.trim().isEmpty
                ? 'AED'
                : currencyCtrl.text.trim().toUpperCase(),
            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
            contactPerson: contactCtrl.text.trim().isEmpty
                ? null
                : contactCtrl.text.trim(),
            website: websiteCtrl.text.trim().isEmpty
                ? null
                : websiteCtrl.text.trim(),
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            isActive: isActive,
          ),
        ),
      );
    }

    nameCtrl.dispose();
    trnCtrl.dispose();
    addressCtrl.dispose();
    addressPrintEnCtrl.dispose();
    addressPrintArCtrl.dispose();
    currencyCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    contactCtrl.dispose();
    websiteCtrl.dispose();
    notesCtrl.dispose();
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
