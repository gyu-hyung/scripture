import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Check maintainState of ModalBottomSheetRoute', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          showModalBottomSheet(context: context, builder: (_) => const Text('Bottom Sheet'));
        },
        child: const Text('Show'),
      );
    }))));
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
  });
}
