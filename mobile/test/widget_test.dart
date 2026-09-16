import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app_settings.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('mostra o menu principal com as seções do CRUD', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.carregar();

    await tester.pumpWidget(OficinaApp(settings: settings));

    expect(find.text('Oficina Mecânica'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Veículos'), findsOneWidget);
    expect(find.text('Peças'), findsOneWidget);
    expect(find.text('Serviços'), findsOneWidget);

    // "Ordens de serviço" fica na última linha da grade, fora da viewport
    // inicial do teste — rola até ela antes de checar.
    await tester.scrollUntilVisible(find.text('Ordens de serviço'), 200);
    expect(find.text('Ordens de serviço'), findsOneWidget);
  });
}
