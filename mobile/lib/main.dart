import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_settings.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.carregar();
  runApp(OficinaApp(settings: settings));
}

class OficinaApp extends StatefulWidget {
  const OficinaApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<OficinaApp> createState() => _OficinaAppState();
}

class _OficinaAppState extends State<OficinaApp> {
  late final ApiClient _api = ApiClient(widget.settings);

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  // Bordas retas (visual "flat"): quase sem arredondamento.
  static const _raioBorda = 4.0;

  ThemeData _construirTema(Brightness brilho) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brilho,
    );

    final formaFlat = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_raioBorda));

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: formaFlat.copyWith(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      // Botões pequenos e "flat", mas com cor cheia pra se destacarem do fundo.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: formaFlat,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: formaFlat,
          elevation: 2,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: formaFlat,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          shape: formaFlat,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: formaFlat,
        sizeConstraints: const BoxConstraints.tightFor(width: 48, height: 48),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_raioBorda)),
      ),
      listTileTheme: ListTileThemeData(shape: formaFlat, dense: true),
      chipTheme: ChipThemeData(shape: formaFlat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.settings.themeMode,
      builder: (context, modo, _) => MaterialApp(
        title: 'Oficina Atividade',
        themeMode: modo,
        theme: _construirTema(Brightness.light),
        darkTheme: _construirTema(Brightness.dark),
        home: HomePage(api: _api, settings: widget.settings),
      ),
    );
  }
}
