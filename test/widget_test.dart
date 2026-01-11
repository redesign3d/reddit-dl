import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/app.dart';
import 'package:reddit_dl/data/app_database.dart';

void main() {
  testWidgets('renders navigation shell', (WidgetTester tester) async {
    final database = AppDatabase.inMemory();
    addTearDown(() async => database.close());

    await tester.pumpWidget(App(database: database));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsWidgets);
    expect(find.text('Queue'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
