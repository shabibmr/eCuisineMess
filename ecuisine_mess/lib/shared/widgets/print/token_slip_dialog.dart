import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/shared/models/token_slip_data.dart';
import 'package:ecuisine_mess/shared/services/printer_service.dart';
import 'package:flutter/material.dart';

export 'package:ecuisine_mess/shared/models/token_slip_data.dart';

class TokenSlipDialog extends StatefulWidget {
  const TokenSlipDialog({
    super.key,
    required this.slip,
    this.isReprint = false,
  });

  /// Convenience for callers that still hold a raw bill map.
  factory TokenSlipDialog.fromMap(
    Map<String, dynamic> bill, {
    Key? key,
    bool isReprint = false,
  }) {
    return TokenSlipDialog(
      key: key,
      slip: TokenSlipData.fromMap(bill),
      isReprint: isReprint,
    );
  }

  final TokenSlipData slip;
  final bool isReprint;

  @override
  State<TokenSlipDialog> createState() => _TokenSlipDialogState();
}

class _TokenSlipDialogState extends State<TokenSlipDialog> {
  bool _printing = false;
  String? _error;

  TokenSlipData get slip => widget.slip;
  bool get isReprint => widget.isReprint;

  @override
  void initState() {
    super.initState();
    _print();
  }

  Future<void> _print() async {
    setState(() {
      _printing = true;
      _error = null;
    });
    try {
      await sl<PrinterService>().printSlip(slip, duplicate: isReprint);
      if (mounted) setState(() => _printing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _printing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'eCuisine Mess Counter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                'MEAL ENTITLEMENT TOKEN',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              const Divider(thickness: 1.5, height: 24),
              if (isReprint)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade600),
                  ),
                  child: const Text(
                    '*** DUPLICATE REPRINT ***',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Center(
                  child: Text(
                    slip.tokenNumber,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Member:',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  Text(
                    slip.memberName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Meal / Cuisine:',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${slip.mealType} • ${slip.cuisine}',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Date & Time:',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  Text(
                    '${slip.date} ${slip.time}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Entitled Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              ...slip.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Entitlement Price:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '0.00 AED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_printing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Printing…', style: TextStyle(fontSize: 12)),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Print failed: $_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              Row(
                children: [
                  if (_error != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _print,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ),
                  if (_error != null) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _printing ? null : () => Navigator.of(context).pop(),
                      icon: Icon(
                        _error != null ? Icons.skip_next : Icons.check,
                        size: 18,
                      ),
                      label: Text(_error != null ? 'Skip' : 'Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
