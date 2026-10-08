import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/check_rfid_available.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/save_member.dart';
import 'package:ecuisine_mess/features/members/presentation/bloc/member_list_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_create_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_date_picker_field.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_dropdown.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_search_field.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:ecuisine_mess/shared/widgets/tables/app_separated_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MemberListPage extends StatelessWidget {
  const MemberListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemberListBloc>()..add(const MemberListStarted()),
      child: const _MemberListView(),
    );
  }
}

class _MemberListView extends StatelessWidget {
  const _MemberListView();

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _showMemberDialog(
    BuildContext context, {
    Member? member,
  }) async {
    final bloc = context.read<MemberListBloc>();
    final cuisines = bloc.state.cuisines;
    final activeCuisines = bloc.state.activeCuisines;

    final params = await showDialog<SaveMemberParams>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MemberFormDialog(
        member: member,
        cuisines: cuisines,
        activeCuisines: activeCuisines,
      ),
    );

    if (params != null && context.mounted) {
      bloc.add(MemberSaveRequested(params));
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemberListBloc, MemberListState>(
      listenWhen: (prev, next) =>
          next.notice != null ||
          (next.status == Status.failure &&
              next.error != null &&
              prev.status == Status.submitting),
      listener: (context, state) {
        if (state.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.notice!)),
          );
          context
              .read<MemberListBloc>()
              .add(const MemberListNoticeConsumed());
        } else if (state.status == Status.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final loading =
            state.status == Status.loading || state.status == Status.initial;
        final showError = state.status == Status.failure &&
            state.members.isEmpty &&
            state.error != null;

        return MasterPage(
          title: 'Members Register',
          subtitle:
              'Manage diners, RFID card links, assigned cuisine & subscription validity',
          loading: loading,
          error: showError ? state.error : null,
          onRetry: () => context
              .read<MemberListBloc>()
              .add(const MemberListRefreshed()),
          isEmpty: !loading && !showError && state.members.isEmpty,
          emptyMessage: 'No members found',
          actions: [
            AppRefreshButton(
              onPressed: () => context
                  .read<MemberListBloc>()
                  .add(const MemberListRefreshed()),
            ),
            const SizedBox(width: 8),
            AppCreateButton(
              label: 'Add Member',
              onPressed: () => _showMemberDialog(context),
            ),
          ],
          toolbar: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hintText: 'Search by name, RFID, or phone…',
                  initialValue: state.search,
                  onChanged: (val) => context
                      .read<MemberListBloc>()
                      .add(MemberListSearchChanged(val)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: AppDropdown<String?>(
                  value: state.statusFilter,
                  label: 'Status',
                  placeholderLabel: 'All',
                  items: const [
                    AppDropdownItem(value: 'ACTIVE', label: 'ACTIVE'),
                    AppDropdownItem(value: 'SUSPENDED', label: 'SUSPENDED'),
                    AppDropdownItem(value: 'EXPIRED', label: 'EXPIRED'),
                  ],
                  onChanged: (v) => context
                      .read<MemberListBloc>()
                      .add(MemberListStatusFilterChanged(v)),
                ),
              ),
            ],
          ),
          child: AppSeparatedListCard(
            itemCount: state.members.length,
            itemBuilder: (context, index) {
              final m = state.members[index];
              final isExpired = m.isExpired;
              final highlight = isExpired || m.isExpiringSoon;
              return InkWell(
                onDoubleTap: () =>
                    _showMemberDialog(context, member: m),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpired
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      Icons.credit_card,
                      color: isExpired
                          ? Colors.red.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                  title: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'RFID: ${m.rfidTag} • Phone: ${m.phone ?? 'N/A'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            m.cuisineName ?? 'No Cuisine Assigned',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            isExpired
                                ? 'EXPIRED'
                                : '${m.daysLeft} days remaining',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: highlight
                                  ? Colors.red
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      AppStatusBadge(
                        type: isExpired
                            ? AppStatusType.expired
                            : (m.status.toUpperCase() == 'SUSPENDED'
                                ? AppStatusType.suspended
                                : AppStatusType.active),
                        compact: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({
    this.member,
    required this.cuisines,
    required this.activeCuisines,
  });

  final Member? member;
  final List<CuisineOption> cuisines;
  final List<CuisineOption> activeCuisines;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _rfidCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late String _validityStart;
  late String _validityEnd;
  String? _cuisineId;
  late String _status;
  String? _rfidError;
  bool _rfidChecking = false;

  late final CheckRfidAvailable _checkRfid;

  @override
  void initState() {
    super.initState();
    _checkRfid = sl<CheckRfidAvailable>();
    final member = widget.member;
    _nameCtrl = TextEditingController(text: member?.name ?? '');
    _rfidCtrl = TextEditingController(text: member?.rfidTag ?? '');
    _phoneCtrl = TextEditingController(text: member?.phone ?? '');
    _emailCtrl = TextEditingController(text: member?.email ?? '');

    final today = DateTime.now();
    _validityStart = member?.validityStart.isNotEmpty == true
        ? member!.validityStart
        : _MemberListView._fmtDate(today);
    _validityEnd = member?.validityEnd.isNotEmpty == true
        ? member!.validityEnd
        : _MemberListView._fmtDate(today.add(const Duration(days: 30)));

    _cuisineId = member?.cuisineId;
    if (_cuisineId != null &&
        _cuisineId!.isNotEmpty &&
        !widget.cuisines.any((c) => c.id == _cuisineId)) {
      _cuisineId = null;
    }

    _status = member?.status.toUpperCase() == 'SUSPENDED'
        ? 'SUSPENDED'
        : 'ACTIVE';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rfidCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<bool> _validateRfid() async {
    final tag = _rfidCtrl.text.trim();
    if (tag.isEmpty) {
      setState(() => _rfidError = 'Required');
      return false;
    }
    setState(() {
      _rfidChecking = true;
      _rfidError = null;
    });
    try {
      final result = await _checkRfid(
        CheckRfidAvailableParams(
          tag: tag,
          excludeMemberId: widget.member?.id,
        ),
      );
      if (!result.available) {
        final who = result.conflictingMemberName ?? 'another member';
        if (mounted) {
          setState(() {
            _rfidChecking = false;
            _rfidError = 'RFID tag already used by $who';
          });
        }
        return false;
      }
      if (mounted) {
        setState(() {
          _rfidChecking = false;
          _rfidError = null;
        });
      }
      return true;
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _rfidChecking = false;
          _rfidError = e.message;
        });
      }
      return false;
    } catch (e) {
      if (mounted) {
        setState(() {
          _rfidChecking = false;
          _rfidError = e.toString();
        });
      }
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _MemberListView._parseDate(_validityStart);
    final end = _MemberListView._parseDate(_validityEnd);
    if (start != null && end != null && start.isAfter(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validity start must be on or before end'),
        ),
      );
      return;
    }
    final rfidOk = await _validateRfid();
    if (!rfidOk) return;

    if (!mounted) return;
    Navigator.of(context).pop(
      SaveMemberParams(
        id: widget.member?.id,
        name: _nameCtrl.text.trim(),
        rfidTag: _rfidCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        cuisineId: _cuisineId,
        validityStart: _validityStart,
        validityEnd: _validityEnd,
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    final cuisineChoices = <CuisineOption>[
      ...widget.activeCuisines,
      if (_cuisineId != null &&
          !widget.activeCuisines.any((c) => c.id == _cuisineId))
        widget.cuisines.firstWhere((c) => c.id == _cuisineId),
    ];

    return AlertDialog(
      title: Text(isEdit ? 'Edit Member' : 'Add Member'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rfidCtrl,
                  decoration: InputDecoration(
                    labelText: 'RFID Tag',
                    border: const OutlineInputBorder(),
                    errorText: _rfidError,
                    suffixIcon: _rfidChecking
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (_) {
                    if (_rfidError != null) {
                      setState(() => _rfidError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppDropdown<String?>(
                  key: ValueKey('cuisine-$_cuisineId'),
                  value: _cuisineId,
                  label: 'Cuisine',
                  placeholderLabel: '— None —',
                  items: cuisineChoices
                      .map(
                        (c) => AppDropdownItem<String?>(
                          value: c.id,
                          label: c.name,
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _cuisineId = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppDatePickerField(
                        label: 'Validity start',
                        value: _MemberListView._parseDate(_validityStart),
                        onChanged: (v) => setState(
                          () => _validityStart = _MemberListView._fmtDate(v),
                        ),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDatePickerField(
                        label: 'Validity end',
                        value: _MemberListView._parseDate(_validityEnd),
                        onChanged: (v) => setState(
                          () => _validityEnd = _MemberListView._fmtDate(v),
                        ),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppDropdown<String>(
                  key: ValueKey('status-$_status'),
                  value: _status,
                  label: 'Status',
                  items: const [
                    AppDropdownItem(
                      value: 'ACTIVE',
                      label: 'ACTIVE',
                    ),
                    AppDropdownItem(
                      value: 'SUSPENDED',
                      label: 'SUSPENDED',
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
