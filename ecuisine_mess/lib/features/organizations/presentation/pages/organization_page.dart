import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';
import 'package:ecuisine_mess/features/organizations/domain/usecases/save_organization.dart';
import 'package:ecuisine_mess/features/organizations/presentation/bloc/organization_list_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_switch_tile.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Singleton organization editor. There is no list: the route opens the
/// empty form or the only stored record.
class OrganizationPage extends StatelessWidget {
  const OrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrganizationListBloc>()
        ..add(const OrganizationListStarted()),
      child: const _OrganizationView(),
    );
  }
}

class _OrganizationView extends StatefulWidget {
  const _OrganizationView();

  @override
  State<_OrganizationView> createState() => _OrganizationViewState();
}

class _OrganizationViewState extends State<_OrganizationView> {
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
  bool _isActive = true;
  String? _boundId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _trnCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _addressPrintEnCtrl = TextEditingController();
    _addressPrintArCtrl = TextEditingController();
    _currencyCtrl = TextEditingController(text: 'AED');
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
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

  void _bind(Organization? org) {
    _boundId = org?.id;
    _nameCtrl.text = org?.orgName ?? '';
    _trnCtrl.text = org?.trn ?? '';
    _addressCtrl.text = org?.address ?? '';
    _addressPrintEnCtrl.text = org?.addressToPrint ?? '';
    _addressPrintArCtrl.text = org?.addressToPrintArabic ?? '';
    _currencyCtrl.text = org?.currency ?? 'AED';
    _phoneCtrl.text = org?.phone ?? '';
    _emailCtrl.text = org?.email ?? '';
    _contactCtrl.text = org?.contactPerson ?? '';
    _websiteCtrl.text = org?.website ?? '';
    _notesCtrl.text = org?.notes ?? '';
    _isActive = org?.isActive ?? true;
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    final existingId =
        context.read<OrganizationListBloc>().state.organization?.id;
    context.read<OrganizationListBloc>().add(
          OrganizationSaveRequested(
            SaveOrganizationParams(
              id: existingId,
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
              phone:
                  _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
              email:
                  _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
              contactPerson: _contactCtrl.text.trim().isEmpty
                  ? null
                  : _contactCtrl.text.trim(),
              website: _websiteCtrl.text.trim().isEmpty
                  ? null
                  : _websiteCtrl.text.trim(),
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              isActive: _isActive,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizationListBloc, OrganizationListState>(
      listenWhen: (previous, current) =>
          (current.status == Status.success &&
              (previous.status == Status.loading ||
                  previous.status == Status.submitting)) ||
          current.notice != null ||
          (current.error != null && current.status == Status.failure),
      listener: (context, state) {
        if (state.status == Status.success) {
          _bind(state.organization);
          setState(() {});
        }
        if (state.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.notice!)),
          );
          context
              .read<OrganizationListBloc>()
              .add(const OrganizationListNoticeConsumed());
        }
        if (state.error != null && state.status == Status.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final submitting = state.status == Status.submitting;
        final initialLoad = state.status == Status.loading &&
            state.organization == null &&
            _boundId == null;
        final awaitingBind = state.organization != null &&
            _boundId != state.organization?.id;
        return MasterPage(
          title: 'Organization',
          subtitle: 'Company details, TRN, and report print headers',
          loading: initialLoad || awaitingBind,
          error: state.status == Status.failure && state.organization == null
              ? state.error
              : null,
          onRetry: () => context
              .read<OrganizationListBloc>()
              .add(const OrganizationListStarted()),
          actions: [
            AppRefreshButton(
              onPressed: submitting
                  ? null
                  : () => context
                      .read<OrganizationListBloc>()
                      .add(const OrganizationListRefreshed()),
            ),
            const SizedBox(width: 8),
            AppSaveButton(
              label: state.organization == null ? 'Create' : 'Save',
              isLoading: submitting,
              onPressed: submitting || initialLoad ? null : _save,
            ),
          ],
          child: initialLoad || awaitingBind
              ? const SizedBox.shrink()
              : Form(
                  key: _formKey,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: SingleChildScrollView(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                              TextFormField(
                                controller: _nameCtrl,
                                enabled: !submitting,
                                autofocus: state.organization == null,
                                decoration: const InputDecoration(
                                  labelText: 'Organization Name *',
                                  hintText: 'e.g. DIT UAE',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _trnCtrl,
                                      enabled: !submitting,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Tax Registration Number (TRN)',
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
                                      enabled: !submitting,
                                      decoration: const InputDecoration(
                                        labelText: 'Currency *',
                                        hintText: 'AED',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressPrintEnCtrl,
                                enabled: !submitting,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Print Header Address (English)',
                                  hintText:
                                      'Header address printed on reports & slips',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressPrintArCtrl,
                                enabled: !submitting,
                                maxLines: 2,
                                textDirection: TextDirection.rtl,
                                decoration: const InputDecoration(
                                  labelText: 'Print Header Address (Arabic)',
                                  hintText:
                                      'عنوان الترويسة للتقارير والإيصالات',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneCtrl,
                                      enabled: !submitting,
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
                                      enabled: !submitting,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return null;
                                        }
                                        if (!v.contains('@')) {
                                          return 'Enter a valid email';
                                        }
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
                                      enabled: !submitting,
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
                                      enabled: !submitting,
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
                                enabled: !submitting,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Physical Address',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _notesCtrl,
                                enabled: !submitting,
                                decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppSwitchTile(
                                title: 'Active',
                                value: _isActive,
                                onChanged: submitting
                                    ? null
                                    : (v) => setState(() => _isActive = v),
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
