import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';
import '../widgets/rfid_tap_simulator.dart';
import '../widgets/token_slip_dialog.dart';
import '../widgets/supervisor_override_dialog.dart';

class CounterKioskScreen extends StatefulWidget {
  const CounterKioskScreen({super.key});

  @override
  State<CounterKioskScreen> createState() => _CounterKioskScreenState();
}

class _CounterKioskScreenState extends State<CounterKioskScreen> {
  final _rfidInputController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CounterProvider>().initMealWindow();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _rfidInputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScanSubmit(String tag) {
    if (tag.trim().isEmpty) return;
    context.read<CounterProvider>().scanRfid(tag.trim());
    _rfidInputController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _handleSaveAndPrint(CounterProvider provider) async {
    final success = await provider.issueToken();
    if (success && mounted && provider.lastIssuedBill != null) {
      showDialog(
        context: context,
        builder: (_) => TokenSlipDialog(bill: provider.lastIssuedBill!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CounterProvider>();
    final tap = provider.currentTap;
    final member = tap?.memberData;
    final items = tap?.items ?? [];
    final activeWin = provider.activeMealWindow;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Active Meal Banner
          Card(
            color: const Color(0xFF0F172A),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, color: Colors.amber, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeWin != null ? '${activeWin['name']} (${activeWin['meal_type']})' : 'Loading meal window...',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          activeWin != null ? 'Window: ${activeWin['start_time']} - ${activeWin['end_time']}' : '',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, size: 10, color: Colors.greenAccent),
                        SizedBox(width: 6),
                        Text('COUNTER READY', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RFID Tap Simulator Bar
          RFIDTapSimulator(onScan: _onScanSubmit),
          const SizedBox(height: 16),

          // Hardware RFID Card Input Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rfidInputController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.nfc),
                    hintText: 'Scan / Tap RFID Card (or enter tag number and press Enter)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _onScanSubmit(_rfidInputController.text),
                    ),
                  ),
                  onSubmitted: _onScanSubmit,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: provider.clearCounter,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear (Esc)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Error Banner if present
          if (provider.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entitlement Rejected', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                        Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (tap?.errorCode == 'ALREADY_SERVED' || tap?.errorCode == 'EXPIRED')
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => SupervisorOverrideDialog(
                            onAuthorized: (supervisor, reason) {
                              provider.grantSupervisorOverride(supervisor, reason);
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('Supervisor Override (F8)'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                    ),
                ],
              ),
            ),

          // Main Kiosk Card: Member details + Entitlement Items
          if (member != null && (tap?.success == true || provider.isOverride))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member Profile Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            member['name']?.toString().substring(0, 1).toUpperCase() ?? 'M',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Code: ${member['member_code']} • Phone: ${member['phone'] ?? "N/A"}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Cuisine: ${member['cuisine_name']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              Text('Validity: ${member['days_left']} days left', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Entitled Items
                    Text(
                      'Entitled Meal Items (${tap?.mealType ?? "LUNCH"}):',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final itm = items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFFDCFCE7),
                            child: Icon(Icons.check, size: 16, color: Colors.green),
                          ),
                          title: Text(itm.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Unit: ${itm.unit} • Category: ${itm.category}'),
                          trailing: Text('Qty: ${itm.quantity.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),

                    const Divider(height: 32),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoice Amount (Meal Entitlement):', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            Text('0.00 AED', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : () => _handleSaveAndPrint(provider),
                          icon: provider.isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.print, size: 20),
                          label: const Text('Save & Issue Token (F10)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
