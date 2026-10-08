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
    final isEdit = member != null;

    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final rfidCtrl = TextEditingController(text: member?.rfidTag ?? '');
    final phoneCtrl = TextEditingController(text: member?.phone ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final today = DateTime.now();
    var validityStart =
        member?.validityStart.isNotEmpty == true
            ? member!.validityStart
            : _fmtDate(today);
    var validityEnd = member?.validityEnd.isNotEmpty == true
        ? member!.validityEnd
        : _fmtDate(today.add(const Duration(days: 30)));
    String? cuisineId = member?.cuisineId;
    if (cuisineId != null &&
        cuisineId.isNotEmpty &&
        !cuisines.any((c) => c.id == cuisineId)) {
      cuisineId = null;
    }
    var status = member?.status.toUpperCase() == 'SUSPENDED'
        ? 'SUSPENDED'
        : 'ACTIVE';
    String? rfidError;
    var rfidChecking = false;
    final formKey = GlobalKey<FormState>();

    final cuisineChoices = <CuisineOption>[
      ...activeCuisines,
      if (cuisineId != null &&
          !activeCuisines.any((c) => c.id == cuisineId))
        cuisines.firstWhere((c) => c.id == cuisineId),
    ];

    final checkRfid = sl<CheckRfidAvailable>();

    Future<bool> validateRfid(StateSetter setLocal) async {
      final tag = rfidCtrl.text.trim();
      if (tag.isEmpty) {
        setLocal(() => rfidError = 'Required');
        return false;
      }
      setLocal(() {
        rfidChecking = true;
        rfidError = null;
      });
      try {
        final result = await checkRfid(
          CheckRfidAvailableParams(
            tag: tag,
            excludeMemberId: member?.id,
          ),
        );
        if (!result.available) {
          final who = result.conflictingMemberName ?? 'another member';
          setLocal(() {
            rfidChecking = false;
            rfidError = 'RFID tag already used by $who';
          });
          return false;
        }
        setLocal(() {
          rfidChecking = false;
          rfidError = null;
        });
        return true;
      } on Failure catch (e) {
        setLocal(() {
          rfidChecking = false;
          rfidError = e.message;
        });
        return false;
      } catch (e) {
        setLocal(() {
          rfidChecking = false;
          rfidError = e.toString();
        });
        return false;
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Member' : 'Add Member'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: rfidCtrl,
                                decoration: InputDecoration(
                                  labelText: 'RFID tag',
                                  border: const OutlineInputBorder(),
                                  errorText: rfidError,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                onChanged: (_) {
                                  if (rfidError != null) {
                                    setLocal(() => rfidError = null);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: OutlinedButton(
                                onPressed: rfidChecking
                                    ? null
                                    : () => validateRfid(setLocal),
                                child: rfidChecking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Check'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        AppDropdown<String?>(
                          key: ValueKey('cuisine-$cuisineId'),
                          value: cuisineId,
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
                          onChanged: (v) => setLocal(() => cuisineId = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppDatePickerField(
                                label: 'Validity start',
                                value: _parseDate(validityStart),
                                onChanged: (v) =>
                                    setLocal(() => validityStart = _fmtDate(v)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2040),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppDatePickerField(
                                label: 'Validity end',
                                value: _parseDate(validityEnd),
                                onChanged: (v) =>
                                    setLocal(() => validityEnd = _fmtDate(v)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2040),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppDropdown<String>(
                          key: ValueKey('status-$status'),
                          value: status,
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
                            if (v != null) setLocal(() => status = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final start = _parseDate(validityStart);
                    final end = _parseDate(validityEnd);
                    if (start != null && end != null && start.isAfter(end)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Validity start must be on or before end',
                          ),
                        ),
                      );
                      return;
                    }
                    final rfidOk = await validateRfid(setLocal);
                    if (!rfidOk) return;
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(isEdit ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      nameCtrl.dispose();
      rfidCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      return;
    }

    bloc.add(
      MemberSaveRequested(
        SaveMemberParams(
          id: member?.id,
          name: nameCtrl.text.trim(),
          rfidTag: rfidCtrl.text.trim(),
          phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          cuisineId: cuisineId,
          validityStart: validityStart,
          validityEnd: validityEnd,
          status: status,
        ),
      ),
    );

    nameCtrl.dispose();
    rfidCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
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
