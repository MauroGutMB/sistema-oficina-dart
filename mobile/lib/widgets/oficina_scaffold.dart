import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import 'app_drawer.dart';

/// Scaffold compartilhado por todas as telas de seção: injeta o menu lateral
/// arrastável e, opcionalmente, um botão de atualizar manual na AppBar.
class OficinaScaffold extends StatelessWidget {
  const OficinaScaffold({
    super.key,
    required this.titulo,
    required this.api,
    required this.settings,
    required this.body,
    this.secaoAtual,
    this.onRefresh,
    this.appBarActions,
    this.floatingActionButton,
  });

  final String titulo;
  final ApiClient api;
  final AppSettings settings;
  final Widget body;
  final String? secaoAtual;
  final VoidCallback? onRefresh;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          ...?appBarActions,
          if (onRefresh != null)
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
            ),
        ],
      ),
      drawer: AppDrawer(api: api, settings: settings, secaoAtual: secaoAtual),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
