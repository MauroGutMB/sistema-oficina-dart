import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chaveApiUrl = 'api_url';
const _chaveModoEscuro = 'modo_escuro';

/// Estado global do app (tema e URL da API), persistido em disco e ouvido
/// pelos widgets via [ValueListenableBuilder]/[AnimatedBuilder].
class AppSettings extends ChangeNotifier {
  AppSettings._(this._apiUrl, ThemeMode temaInicial) : themeMode = ValueNotifier(temaInicial);

  final ValueNotifier<ThemeMode> themeMode;
  String _apiUrl;

  String get apiUrl => _apiUrl;

  static Future<AppSettings> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final apiUrl = prefs.getString(_chaveApiUrl) ?? 'http://localhost:3000';
    final escuro = prefs.getBool(_chaveModoEscuro);
    final tema = escuro == null
        ? ThemeMode.system
        : (escuro ? ThemeMode.dark : ThemeMode.light);
    return AppSettings._(apiUrl, tema);
  }

  Future<void> definirModoEscuro(bool escuro) async {
    themeMode.value = escuro ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveModoEscuro, escuro);
  }

  Future<void> atualizarApiUrl(String novaUrl) async {
    _apiUrl = novaUrl;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveApiUrl, novaUrl);
  }
}
