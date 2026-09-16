import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app_settings.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('mostra o menu principal com as seções do CRUD', (WidgetTester tester) async {
    // Simula uma tela de celular alta (bem diferente do 800x600 padrão do
    // teste), pra que o conteúdo da home caiba sem precisar rolar — a
    // ListView só constrói de verdade o que está na viewport + um cache
    // pequeno, então num viewport baixo o card de Ordens/status nem chegam
    // a existir na árvore de widgets.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.carregar();

    await tester.pumpWidget(OficinaApp(settings: settings));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Oficina Mecânica'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Veículos'), findsOneWidget);
    expect(find.text('Peças'), findsOneWidget);
    expect(find.text('Serviços'), findsOneWidget);
    expect(find.text('Ordens de serviço'), findsOneWidget);
  });
}
