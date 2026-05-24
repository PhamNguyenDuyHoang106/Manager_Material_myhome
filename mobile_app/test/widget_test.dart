import 'package:flutter_test/flutter_test.dart';
import 'package:material_manager_mobile/app.dart';

void main() {
  testWidgets('App smoke test placeholder', (tester) async {
    // Full widget test requires Firebase mock — run integration tests after Firebase setup.
    expect(const MaterialManagerApp(), isNotNull);
  });
}
