import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/daily_menu_editor_bloc.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_item_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('quantity starts at 1 and cannot go below 1', (tester) async {
    await tester.pumpWidget(const _QtyHarness());

    expect(_qtyText(), '1');

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(_qtyText(), '1');

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(_qtyText(), '2');

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(_qtyText(), '1');

    final decrease = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(decrease.onPressed, isNull);
  });
}

String _qtyText() {
  final text = find
      .byKey(const ValueKey('menu-line-qty-item-1'))
      .evaluate()
      .single
      .widget as Text;
  return text.data!;
}

class _QtyHarness extends StatefulWidget {
  const _QtyHarness();

  @override
  State<_QtyHarness> createState() => _QtyHarnessState();
}

class _QtyHarnessState extends State<_QtyHarness> {
  double _qty = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 320,
          child: MenuItemGrid(
            items: [
              MenuSlotLine(
                itemId: 'item-1',
                itemName: 'Rice',
                unit: 'Plate',
                quantity: _qty,
              ),
            ],
            availableMappedItems: const [
              CuisineItemMapping(
                itemId: 'item-2',
                itemName: 'Dal',
                unit: 'Bowl',
                defaultQty: 1,
                sortOrder: 0,
              ),
            ],
            readOnly: false,
            hasMappedItems: true,
            cuisineName: 'South Indian',
            onAddItem: (_) {},
            onRemoveItem: (_) {},
            onQtyChanged: (_, qty) => setState(() => _qty = qty),
          ),
        ),
      ),
    );
  }
}
