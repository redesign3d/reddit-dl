import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/app.dart';

void main() {
  testWidgets('renders navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsWidgets);
    expect(find.text('Queue'), findsWidgets);
  });
}
