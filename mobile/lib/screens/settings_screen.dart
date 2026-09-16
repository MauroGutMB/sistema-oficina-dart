import 'package:flutter/material.dart';

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
  late final _urlController = TextEditingController(text: widget.settings.apiUrl);
  bool _testando = false;
  bool? _ultimoResultado;

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
