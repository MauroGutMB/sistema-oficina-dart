import 'package:flutter/material.dart';

import '../api_client.dart';
import '../app_settings.dart';
import 'app_drawer.dart';

/// Scaffold compartilhado por todas as telas de seção: injeta o menu lateral
/// arrastável e, opcionalmente, uma lupa de pesquisa na AppBar (em vez de
/// botão de atualizar — puxar a lista pra baixo já recarrega).
class OficinaScaffold extends StatefulWidget {
  const OficinaScaffold({
    super.key,
    required this.titulo,
    required this.api,
    required this.settings,
    required this.body,
    this.secaoAtual,
    this.appBarActions,
    this.floatingActionButton,
    this.searchHint,
    this.onSearchChanged,
  });

  final String titulo;
  final ApiClient api;
  final AppSettings settings;
  final Widget body;
  final String? secaoAtual;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  /// Texto de exemplo mostrado no campo de pesquisa. Só faz sentido junto
  /// com [onSearchChanged] — sem ele, a lupa nem aparece.
  final String? searchHint;

  /// Chamado a cada mudança no texto de pesquisa (inclusive `''` ao fechar).
  /// A tela dona da lista é quem filtra os resultados com esse texto.
  final ValueChanged<String>? onSearchChanged;

  @override
  State<OficinaScaffold> createState() => _OficinaScaffoldState();
}

class _OficinaScaffoldState extends State<OficinaScaffold> {
  bool _pesquisando = false;
  final _controladorPesquisa = TextEditingController();

  void _abrirPesquisa() => setState(() => _pesquisando = true);

  void _fecharPesquisa() {
    _controladorPesquisa.clear();
    widget.onSearchChanged?.call('');
    setState(() => _pesquisando = false);
  }

  @override
  void dispose() {
    _controladorPesquisa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temPesquisa = widget.onSearchChanged != null;

    return Scaffold(
      appBar: AppBar(
        title: _pesquisando
            ? TextField(
                controller: _controladorPesquisa,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Pesquisar...',
                  border: InputBorder.none,
                ),
                onChanged: widget.onSearchChanged,
              )
            : Text(widget.titulo),
        actions: _pesquisando
            ? [
                IconButton(
                  tooltip: 'Fechar pesquisa',
                  icon: const Icon(Icons.close),
                  onPressed: _fecharPesquisa,
                ),
              ]
            : [
                ...?widget.appBarActions,
                if (temPesquisa)
                  IconButton(
                    tooltip: 'Pesquisar',
                    icon: const Icon(Icons.search),
                    onPressed: _abrirPesquisa,
                  ),
              ],
      ),
      drawer: AppDrawer(api: widget.api, settings: widget.settings, secaoAtual: widget.secaoAtual),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
