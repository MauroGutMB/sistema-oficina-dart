import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api, required this.settings});

  final ApiClient api;
  final AppSettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Publicada pelo expor-api-rede.sh — guarda só a URL atual da API (ou
  // "offline" quando a exposição está fechada).
  static const _gistRawUrl =
      'https://gist.githubusercontent.com/MauroGutMB/f82d8d6aaf68df1bfba2a2bc4eba52eb/raw/gistfile1.txt';

  late final _urlController = TextEditingController(text: widget.settings.apiUrl);
  bool _testando = false;
  bool? _ultimoResultado;

  bool _verificandoAutomatica = true;
  String? _urlAutomatica;

  @override
  void initState() {
    super.initState();
    _verificarConexaoAutomatica();
  }

  Future<void> _salvarEtestar() async {
    final novaUrl = _urlController.text.trim();
    if (novaUrl.isEmpty) return;

    await widget.settings.atualizarApiUrl(novaUrl);
    setState(() {
      _testando = true;
      _ultimoResultado = null;
    });

    final ok = await widget.api.testarConexao();

    if (!mounted) return;
    setState(() {
      _testando = false;
      _ultimoResultado = ok;
    });
  }

  /// Busca a URL publicada no gist e confere se ela responde agora. Só
  /// habilita o botão de conexão automática se as duas coisas derem certo.
  Future<void> _verificarConexaoAutomatica() async {
    setState(() {
      _verificandoAutomatica = true;
      _urlAutomatica = null;
    });

    final urlDoGist = await _buscarUrlDoGist();
    final alcancavel = urlDoGist != null && await _urlResponde(urlDoGist);

    if (!mounted) return;
    setState(() {
      _verificandoAutomatica = false;
      _urlAutomatica = alcancavel ? urlDoGist : null;
    });
  }

  Future<String?> _buscarUrlDoGist() async {
    try {
      // query pra furar o cache da CDN do GitHub, que segura o raw por uns
      // minutos depois de cada atualização do gist.
      final uri = Uri.parse(
        '$_gistRawUrl?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final resposta = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resposta.statusCode != 200) return null;

      final conteudo = resposta.body.trim();
      if (!conteudo.startsWith('http')) return null; // "offline" ou vazio
      return conteudo;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _urlResponde(String url) async {
    try {
      final resposta = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      return resposta.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<void> _usarConexaoAutomatica() async {
    final url = _urlAutomatica;
    if (url == null) return;

    _urlController.text = url;
    await _salvarEtestar();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conexão')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('URL da API', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL base',
                      hintText: 'http://localhost:3000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _testando ? null : _salvarEtestar,
                        icon: _testando
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: const Text('Salvar e testar'),
                      ),
                      const SizedBox(width: 12),
                      if (_ultimoResultado == true)
                        const _StatusChip(
                          texto: 'Conectado',
                          cor: Colors.green,
                          icone: Icons.check_circle,
                        ),
                      if (_ultimoResultado == false)
                        const _StatusChip(
                          texto: 'Falhou',
                          cor: Colors.red,
                          icone: Icons.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Conexão automática', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Verificar de novo',
                        icon: const Icon(Icons.refresh),
                        onPressed: _verificandoAutomatica ? null : _verificarConexaoAutomatica,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Busca a URL mais recente publicada e confere se ela está respondendo agora.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    // desabilitado (cinza) quando ainda não achou uma URL
                    // alcançável — só clicável quando há uma de verdade.
                    onPressed: _urlAutomatica != null ? _usarConexaoAutomatica : null,
                    icon: _verificandoAutomatica
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt),
                    label: const Text('Conexão Automática'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _verificandoAutomatica
                        ? 'Verificando disponibilidade...'
                        : (_urlAutomatica != null
                            ? 'Disponível: $_urlAutomatica'
                            : 'Nenhuma URL alcançável no momento.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.texto, required this.cor, required this.icone});

  final String texto;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icone, color: cor, size: 18),
      label: Text(texto),
      backgroundColor: cor.withValues(alpha: 0.12),
    );
  }
}
