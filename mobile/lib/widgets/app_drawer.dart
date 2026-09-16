import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import '../navigation.dart';
import '../screens/settings_screen.dart';

/// Menu lateral (arrastável a partir da borda esquerda) com acesso a todas
/// as seções do CRUD, presente em todas as telas do app.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.api,
    required this.settings,
    this.secaoAtual,
  });

  final ApiClient api;
  final AppSettings settings;
  final String? secaoAtual;

  // Empilha a tela (em vez de substituir), pra manter o botão de voltar
  // padrão do Flutter disponível em toda navegação feita pelo menu.
  void _navegarPara(BuildContext context, Widget tela) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  void _irParaInicio(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Oficina Mecânica',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Início'),
              selected: secaoAtual == null,
              onTap: () => _irParaInicio(context),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  for (final secao in secoes)
                    ListTile(
                      leading: Icon(secao.icone),
                      title: Text(secao.titulo),
                      selected: secaoAtual == secao.titulo,
                      onTap: () => _navegarPara(context, secao.builder(api, settings)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.wifi_tethering),
              title: const Text('Conexão com a API'),
              subtitle: Text(settings.apiUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _navegarPara(context, SettingsScreen(api: api, settings: settings)),
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: settings.themeMode,
              builder: (context, tema, _) {
                // Quando o tema segue o sistema, reflete o brilho real do
                // aparelho no switch em vez de sempre mostrar "desligado".
                final estaEscuro = tema == ThemeMode.system
                    ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                    : tema == ThemeMode.dark;

                return SwitchListTile(
                  secondary: Icon(estaEscuro ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Modo escuro'),
                  value: estaEscuro,
                  onChanged: (valor) => settings.definirModoEscuro(valor),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'CRUD mobile feito em Flutter por Mauro Gutemberg',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
